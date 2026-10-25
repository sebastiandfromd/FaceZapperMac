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
    m_history.append(Entry{p});
    m_index = 0;
    emitCardChanged();
}

void LearningSession::clear()
{
    // ratings stay with the persons, only the way back is forgotten
    m_history.clear();
    m_index = -1;
    emitCardChanged();
}

bool LearningSession::finishCurrent()
{
    if (m_index < 0) return false;
    Entry &e = m_history[m_index];
    const Rating r = rate(e);
    applyRating(e, r);
    return r != Rating::AGAIN;
}

void LearningSession::next()
{
    if (m_index < 0) return;
    if (m_index == m_history.size() - 1) {
        PersonData *p = pickNextPerson();
        if (!p) return;
        m_history.append(Entry{p});
    }
    m_index++;
    emitCardChanged();
}

void LearningSession::back()
{
    if (m_index <= 0) return;
    m_index--;
    undoRating(m_history[m_index]);
    emitCardChanged();
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
    Entry &e = m_history[m_index];
    const int pressedIndex = int(m_keys.indexOf(letter));
    e.typed.append(letter);
    if (e.solutionVisible && typedIsCorrect()) {
        // correct letter while the name is shown: go on as with a new card (still not known)
        e.solutionVisible = false;
        emit solutionShownChanged();
    }
    emit typedChanged();
    updateKeys(letter, pressedIndex);
}

void LearningSession::backspace()
{
    if (m_index < 0 || m_history[m_index].typed.isEmpty()) return;
    Entry &e = m_history[m_index];
    const bool wasWrong = !typedIsCorrect();
    e.typed.chop(1);
    if (wasWrong && typedIsCorrect()) e.corrections++; // noticed the slip without a hint
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

int LearningSession::corrections() const
{
    return m_index < 0 ? 0 : m_history.at(m_index).corrections;
}

QString LearningSession::targetName() const
{
    const PersonData *p = currentPerson();
    if (!p) return QString();
    return QString(p->firstName() + u' ' + p->familyName()).simplified();
}

bool LearningSession::typedIsCorrect() const
{
    return targetName().startsWith(typed(), Qt::CaseInsensitive);
}

qint64 LearningSession::activeMs() const
{
    const qint64 now = m_nowMs();
    const qint64 paused = m_pausedMs + (m_pauseStart >= 0 ? now - m_pauseStart : 0);
    return now - m_cardStart - paused;
}

PersonData *LearningSession::pickNextPerson() const
{
    // front of the card box, but never the card just shown
    const PersonData *last = currentPerson();
    for (PersonData *p : m_deck)
        if (p != last) return p;
    return m_deck.isEmpty() ? nullptr : m_deck.first();
}

LearningSession::Rating LearningSession::rate(const Entry &e) const
{
    if (e.solutionShown || !typedIsCorrect()) return Rating::AGAIN;
    if (e.corrections > 0) return Rating::UNSURE;
    if (!e.typed.isEmpty()) return Rating::GOOD;
    const double seconds = activeMs() / 1000.0;
    if (seconds < m_settings.easySeconds) return Rating::VERY_EASY;
    if (seconds > m_settings.unsureSeconds) return Rating::UNSURE;
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

void LearningSession::updateKeys(const QString &pressed, int pressedIndex)
{
    m_keys = (m_letterModel && m_index >= 0) ? m_letterModel->keys(targetName(), typed()) : QStringList();
    // the key just pressed stays where it was if it's offered again ("Hanna", "Emma"), so a quick
    // second tap hits the same letter. Done for every repeated letter, not only correct ones,
    // so a key that didn't move gives nothing away.
    if (!pressed.isEmpty() && pressedIndex >= 0 && pressedIndex < m_keys.size()) {
        const int i = int(m_keys.indexOf(pressed));
        if (i >= 0 && i != pressedIndex) m_keys.move(i, pressedIndex);
    }
    emit keysChanged();
}

void LearningSession::emitCardChanged()
{
    restartClock(); // every card (also one returned to) is timed afresh
    emit currentChanged();
    emit typedChanged();
    emit solutionShownChanged();
    updateKeys();
}
