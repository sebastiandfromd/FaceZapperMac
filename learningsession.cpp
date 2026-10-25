#include "learningsession.h"
#include <QRandomGenerator>

LearningSession::LearningSession(QObject *parent) : QObject(parent)
{
}

void LearningSession::start()
{
    clear();
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
    const bool known = !e.solutionShown && typedIsCorrect();
    applyResult(e, known ? Result::KNOWN : Result::NOT_KNOWN);
    return known;
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
    undoResult(m_history[m_index]);
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

PersonData *LearningSession::pickNextPerson() const
{
    // step 1: random choice, avoiding the card just shown (card box comes in step 3)
    if (!m_persons || m_persons->isEmpty()) return nullptr;
    const PersonData *last = currentPerson();
    PersonData *p = nullptr;
    do {
        p = m_persons->at(int(QRandomGenerator::global()->bounded(m_persons->size())));
    } while (p == last && m_persons->size() > 1);
    return p;
}

void LearningSession::applyResult(Entry &e, Result r)
{
    undoResult(e);
    e.result = r;
    if (r == Result::KNOWN) e.person->setWins(e.person->wins() + 1);
    else if (r == Result::NOT_KNOWN) e.person->setFails(e.person->fails() + 1);
}

void LearningSession::undoResult(Entry &e)
{
    if (e.result == Result::KNOWN) e.person->setWins(e.person->wins() - 1);
    else if (e.result == Result::NOT_KNOWN) e.person->setFails(e.person->fails() - 1);
    e.result = Result::NONE;
}

void LearningSession::updateKeys()
{
    m_keys = (m_letterModel && m_index >= 0) ? m_letterModel->keys(targetName(), typed()) : QStringList();
    emit keysChanged();
}

void LearningSession::emitCardChanged()
{
    emit currentChanged();
    emit typedChanged();
    emit solutionShownChanged();
    updateKeys();
}
