#ifndef LEARNINGSESSION_H
#define LEARNINGSESSION_H

#include <QObject>
#include <QList>
#include <QVector>
#include "persondata.h"

// One run through the cards of a folder. Keeps a history of the shown cards,
// so the user can go back (any number of steps) and redo an answer.
// Invariant: entries from the current index on are not rated - back() undoes
// the rating of the card it returns to.
class LearningSession : public QObject
{
    Q_OBJECT

public:
    enum class Result {
        NONE = 0,       // not rated (yet)
        KNOWN = 1,      // swiped without wrong letter and without "Lösung"
        NOT_KNOWN = 2   // "Lösung" was shown or a wrong letter was typed
    };
    Q_ENUM(Result)

    explicit LearningSession(QObject *parent = nullptr);

    void setPersons(const QVector<PersonData*> *persons) { m_persons = persons; }

    Q_INVOKABLE void start();
    Q_INVOKABLE void clear();
    Q_INVOKABLE bool finishCurrent(); // rates the current card, returns true if known
    Q_INVOKABLE void next();          // shows the next card (from history or a new one)
    Q_INVOKABLE void back();          // returns to the previous card and undoes its rating
    Q_INVOKABLE void showSolution();
    Q_INVOKABLE void typeLetter(const QString &letter);
    Q_INVOKABLE void backspace();

    PersonData *currentPerson() const;
    QString typed() const;
    bool solutionShown() const;
    bool canGoBack() const { return m_index > 0; }
    QString targetName() const; // what the user is supposed to type for the current card
    bool typedIsCorrect() const; // typed text is a (case-insensitive) prefix of targetName()

signals:
    void currentChanged();
    void typedChanged();
    void solutionShownChanged();

private:
    struct Entry {
        PersonData *person = nullptr;
        QString typed;
        bool solutionShown = false;
        Result result = Result::NONE;
    };

    PersonData *pickNextPerson() const;
    void applyResult(Entry &e, Result r);
    void undoResult(Entry &e);

    const QVector<PersonData*> *m_persons = nullptr;
    QList<Entry> m_history;
    int m_index = -1;

    Q_PROPERTY(PersonData* currentPerson READ currentPerson NOTIFY currentChanged)
    Q_PROPERTY(QString typed READ typed NOTIFY typedChanged)
    Q_PROPERTY(bool solutionShown READ solutionShown NOTIFY solutionShownChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY currentChanged)
    Q_PROPERTY(QString targetName READ targetName NOTIFY currentChanged)
};

#endif // LEARNINGSESSION_H
