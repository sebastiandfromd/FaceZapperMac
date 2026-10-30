#include "learningsession.h"
#include <QRandomGenerator>
#include <QElapsedTimer>
#include <QSet>
#include <algorithm>
#include <memory>

LearningSession::LearningSession(QObject *parent) : QObject(parent)
{
    auto timer = std::make_shared<QElapsedTimer>();
    timer->start();
    m_nowMs = [timer] { return timer->elapsed(); };
}

void LearningSession::setCardBoxSettings(const CardBoxSettings &settings)
{
    const bool targetChanged = settings.targetMode != m_settings.targetMode;
    m_settings = settings;
    emit statsChanged(); // "sicher" depends on learnedStreak
    if (targetChanged && m_index >= 0) {
        m_history[m_index].typed.clear(); // the typed text belonged to the old target
        emitCardChanged();
    }
}

void LearningSession::setAppActive(bool active)
{
    const qint64 now = m_nowMs();
    if (!active && m_pauseStart < 0) {
        m_pauseStart = now;
    } else if (active && m_pauseStart >= 0) {
        m_pausedMs += now - m_pauseStart;
        m_pauseStart = -1;
    }
}

void LearningSession::start()
{
    clear();
    buildDeck();
    PersonData *p = pickNextPerson();
    if (!p) return;
    appendEntry(p);
    m_index = 0;
    emitCardChanged();
}

void LearningSession::clear()
{
    // ratings stay with the persons, only the way back is forgotten
    m_history.clear();
    m_index = -1;
    emitCardChanged();
    emit statsChanged();
}

int LearningSession::seenCount() const
{
    if (!m_persons) return 0;
    return int(std::count_if(m_persons->cbegin(), m_persons->cend(),
                             [](const PersonData *p) { return p->lastSeen().isValid(); }));
}

int LearningSession::learnedCount() const
{
    if (!m_persons) return 0;
    const int needed = m_settings.learnedStreak;
    return int(std::count_if(m_persons->cbegin(), m_persons->cend(),
                             [needed](const PersonData *p) { return p->streak() >= needed; }));
}

int LearningSession::finishCurrent()
{
    if (m_index < 0) return int(Outcome::NOT_KNOWN);
    const int outcome = currentOutcome();
    Entry &e = m_history[m_index];
    if (e.inRetry) return outcome; // second look after a red answer: nothing is counted
    applyRating(e, rate(e));
    emit rated();
    emit statsChanged();
    return outcome;
}

int LearningSession::currentOutcome() const
{
    if (m_index < 0) return int(Outcome::NOT_KNOWN);
    const Entry &e = m_history.at(m_index);
    // the same condition as Rating::AGAIN in rate() - only the time decides between the other ratings
    if (!e.solutionShown && typedIsCorrect()) return int(Outcome::KNOWN);
    if (!typedIsCorrect()) return int(Outcome::NOT_KNOWN); // a wrong letter left: another look
    if (e.inRetry && e.typed.isEmpty()) return int(Outcome::SKIPPED);
    // the name had been shown: typing it correctly since earns yellow (a slip taken back with ←
    // doesn't matter), nothing typed is red
    return int(e.typed.isEmpty() ? Outcome::SEEN : Outcome::PRACTICED);
}

void LearningSession::retry()
{
    if (m_index < 0) return;
    Entry &e = m_history[m_index];
    e.inRetry = true;
    e.solutionShown = true;
    e.solutionVisible = true;
    e.typed.clear();
    restartClock();
    emit typedChanged();
    emit solutionShownChanged();
    updateKeys();
}

void LearningSession::next()
{
    if (m_index < 0) return;
    if (m_index == m_history.size() - 1) {
        PersonData *p = pickNextPerson();
        if (!p) return;
        appendEntry(p);
    }
    m_index++;
    emitCardChanged();
}

void LearningSession::back()
{
    if (m_index <= 0) return;
    // a card in its retry is already rated - undo it too, so all cards from here on are unrated
    undoRating(m_history[m_index]);
    m_history[m_index].inRetry = false;
    m_index--;
    undoRating(m_history[m_index]);
    m_history[m_index].inRetry = false;
    m_history[m_index].thinkingMs = -1; // answered anew, timed anew
    emitCardChanged();
    emit rated();
    emit statsChanged();
}

void LearningSession::showSolution()
{
    if (m_index < 0) return;
    Entry &e = m_history[m_index];
    e.solutionShown = true;
    e.solutionVisible = true;
    e.typed.clear(); // start over, typing the name helps learning it
    emit typedChanged();
    emit solutionShownChanged();
    updateKeys();
}

void LearningSession::typeLetter(const QString &letter)
{
    if (m_index < 0) return;
    if (!typedIsCorrect()) {
        // the wrong letter wasn't taken back: resolve, counts as not known
        showSolution();
        return;
    }
    noteFirstKey();
    Entry &e = m_history[m_index];
    e.typed.append(letter);
    if (e.solutionVisible && typedIsCorrect()) {
        // correct letter while the name is shown: go on as with a new card (still not known)
        e.solutionVisible = false;
        emit solutionShownChanged();
    }
    emit typedChanged();
    updateKeys();
}

void LearningSession::backspace()
{
    if (m_index < 0 || m_history[m_index].typed.isEmpty()) return;
    noteFirstKey();
    m_history[m_index].typed.chop(1); // never counts against the answer
    emit typedChanged();
    updateKeys();
}

PersonData *LearningSession::currentPerson() const
{
    return m_index < 0 ? nullptr : m_history.at(m_index).person;
}

QString LearningSession::typed() const
{
    return m_index < 0 ? QString() : m_history.at(m_index).typed;
}

bool LearningSession::solutionShown() const
{
    return m_index >= 0 && m_history.at(m_index).solutionShown;
}

bool LearningSession::solutionVisible() const
{
    return m_index >= 0 && m_history.at(m_index).solutionVisible;
}

qint64 LearningSession::thinkingMs() const
{
    if (m_index < 0) return 0;
    const qint64 t = m_history.at(m_index).thinkingMs;
    return t >= 0 ? t : activeMs();
}

void LearningSession::noteFirstKey()
{
    if (m_index >= 0 && m_history[m_index].thinkingMs < 0)
        m_history[m_index].thinkingMs = activeMs();
}

QString LearningSession::targetName() const
{
    const PersonData *p = currentPerson();
    if (!p) return QString();
    switch (m_settings.targetMode) {
    case 0: return p->firstName().simplified();
    case 1: return p->familyName().simplified();
    case 3: return QString(p->familyName().simplified() + u", " + p->firstName().simplified());
    default: return QString(p->firstName() + u' ' + p->familyName()).simplified();
    }
}

QStringList LearningSession::acceptedTargets() const
{
    const QString full = targetName();
    const PersonData *p = currentPerson();
    if (!p || m_settings.targetMode != 2) return {full}; // other orders: leaving out = stopping early
    // "Anna Lena Marie Groß": also "Anna Lena Groß" and "Anna Groß" - given names may be dropped
    // from the end, separated by spaces only ("Anna-Lena" is one name)
    const QStringList given = p->firstName().simplified().split(u' ', Qt::SkipEmptyParts);
    const QString family = p->familyName().simplified();
    QStringList targets{full};
    if (family.isEmpty()) return targets;
    for (qsizetype n = given.size() - 1; n >= 1; --n)
        targets << QStringList(given.mid(0, n)).join(u' ') + u' ' + family;
    return targets;
}

bool LearningSession::typedIsCorrect() const
{
    // same upper-casing as the keyboard: Unicode case folding would treat the "I" key and a
    // Turkish dotless "ı" (Yıldırım) as different letters
    const QString t = LetterModel::normalize(typed());
    for (const QString &target : acceptedTargets())
        if (LetterModel::normalize(target).startsWith(t)) return true;
    return false;
}

qint64 LearningSession::activeMs() const
{
    const qint64 now = m_nowMs();
    const qint64 paused = m_pausedMs + (m_pauseStart >= 0 ? now - m_pauseStart : 0);
    return now - m_cardStart - paused;
}

PersonData *LearningSession::pickNextPerson() const
{
    const PersonData *last = currentPerson();
    // after newCardInterval-1 already known faces in a row, bring in one never seen before,
    // so faces further back in the box aren't kept waiting by the hard ones in front
    int seenInARow = 0;
    for (int i = int(m_history.size()) - 1; i >= 0 && !m_history.at(i).wasNew; --i)
        seenInARow++;
    if (seenInARow >= m_settings.newCardInterval - 1) {
        for (PersonData *p : m_deck)
            if (p != last && !p->lastSeen().isValid()) return p;
    }
    // otherwise the front of the card box, but never the card just shown
    for (PersonData *p : m_deck)
        if (p != last) return p;
    return m_deck.isEmpty() ? nullptr : m_deck.first();
}

void LearningSession::appendEntry(PersonData *p)
{
    Entry e;
    e.person = p;
    e.wasNew = !p->lastSeen().isValid();
    m_history.append(e);
}

LearningSession::Rating LearningSession::rate(const Entry &e) const
{
    if (e.solutionShown || !typedIsCorrect()) return Rating::AGAIN;
    // thinking time: until the first key, or until the swipe if nothing was typed
    const double seconds = thinkingMs() / 1000.0;
    if (seconds > m_settings.unsureSeconds) return Rating::UNSURE;
    if (e.typed.isEmpty() && seconds < m_settings.easySeconds) return Rating::VERY_EASY;
    return Rating::GOOD;
}

void LearningSession::applyRating(Entry &e, Rating r)
{
    undoRating(e); // rating the same card twice (double swipe) must not count twice
    PersonData *p = e.person;
    e.deckBefore = m_deck;
    e.streakBefore = p->streak();
    e.lastSeenBefore = p->lastSeen();
    e.rating = r;

    int offset = m_settings.againOffset;
    switch (r) {
    case Rating::VERY_EASY:
        p->setStreak(p->streak() + 1);
        offset = m_settings.easyFactor << qMin(p->streak(), 20);
        break;
    case Rating::GOOD:
        p->setStreak(p->streak() + 1);
        offset = m_settings.goodFactor << qMin(p->streak(), 20);
        break;
    case Rating::UNSURE:
        offset = m_settings.unsureOffset;
        break;
    case Rating::AGAIN:
    case Rating::NONE:
        p->setStreak(0);
        offset = m_settings.againOffset;
        break;
    }
    if (r == Rating::AGAIN) p->setFails(p->fails() + 1);
    else p->setWins(p->wins() + 1);
    p->setLastSeen(QDateTime::currentDateTime());

    // move the card back in the box: `offset` other cards come first (at least one)
    m_deck.removeAll(p);
    const int size = int(m_deck.size());
    m_deck.insert(std::clamp(offset, qMin(1, size), size), p);
}

void LearningSession::undoRating(Entry &e)
{
    if (e.rating == Rating::NONE) return;
    PersonData *p = e.person;
    if (e.rating == Rating::AGAIN) p->setFails(p->fails() - 1);
    else p->setWins(p->wins() - 1);
    p->setStreak(e.streakBefore);
    p->setLastSeen(e.lastSeenBefore);
    m_deck = e.deckBefore;
    e.rating = Rating::NONE;
}

void LearningSession::buildDeck()
{
    // keep the existing order (e.g. loaded from the folder's data), drop cards that are gone
    // and put new cards in at random places
    if (!m_persons) {
        m_deck.clear();
        return;
    }
    const QSet<PersonData*> valid(m_persons->cbegin(), m_persons->cend());
    m_deck.removeIf([&valid](PersonData *p) { return !valid.contains(p); });
    for (PersonData *p : *m_persons) {
        if (m_deck.contains(p)) continue;
        m_deck.insert(int(QRandomGenerator::global()->bounded(m_deck.size() + 1)), p);
    }
}

void LearningSession::restartClock()
{
    m_cardStart = m_nowMs();
    m_pausedMs = 0;
    if (m_pauseStart >= 0) m_pauseStart = m_cardStart;
}

void LearningSession::updateKeys(bool keepPositions)
{
    const QStringList fresh = (m_letterModel && m_index >= 0)
                                  ? m_letterModel->keys(acceptedTargets(), typed()) : QStringList();
    if (!keepPositions || m_keys.size() != fresh.size()) {
        m_keys = fresh;
        emit keysChanged();
        return;
    }
    // every key that is offered again stays in its place ("Hanna": the second n where the first
    // one was; "A" -> "a" counts as the same key) - for decoys and correct keys alike, so a key
    // that didn't move gives nothing away. New keys fill the free places in alphabetical order.
    QStringList placed(fresh.size());
    QStringList rest;
    for (const QString &k : fresh) {
        qsizetype old = -1;
        for (qsizetype i = 0; i < m_keys.size(); ++i)
            if (m_keys.at(i).compare(k, Qt::CaseInsensitive) == 0) { old = i; break; }
        if (old >= 0) placed[old] = k;
        else rest << k;
    }
    for (QString &slot : placed)
        if (slot.isNull()) slot = rest.takeFirst(); // fresh is sorted, so rest is too
    m_keys = placed;
    emit keysChanged();
}

void LearningSession::emitCardChanged()
{
    restartClock(); // every card (also one returned to) is timed afresh
    emit currentChanged();
    emit typedChanged();
    emit solutionShownChanged();
    updateKeys(false); // a new card starts with a freshly sorted keyboard
}
