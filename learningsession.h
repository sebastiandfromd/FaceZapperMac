#ifndef LEARNINGSESSION_H
#define LEARNINGSESSION_H

#include <QObject>
#include <QList>
#include <QVector>
#include <QDateTime>
#include <functional>
#include "persondata.h"
#include "lettermodel.h"

// How far a card moves back in the card box. Editable on the settings page.
struct CardBoxSettings {
    double easySeconds = 2;   // swiped without letters faster than this: very easy
    double unsureSeconds = 8; // looked longer than this, then swiped without letters: unsure
    int easyFactor = 4;       // very easy: offset = easyFactor * 2^streak
    int goodFactor = 2;       // good: offset = goodFactor * 2^streak
    int unsureOffset = 4;     // unsure (also: slip corrected on one's own)
    int againOffset = 3;      // not known: comes back soon
};

// One run through the cards of a folder. Keeps a history of the shown cards,
// so the user can go back (any number of steps) and redo an answer.
// Invariant: entries from the current index on are not rated - back() undoes
// the rating of the card it returns to (including its move in the card box).
class LearningSession : public QObject
{
    Q_OBJECT

public:
    enum class Rating {
        NONE = 0,       // not rated (yet)
        VERY_EASY = 1,  // swiped quickly without typing
        GOOD = 2,       // typed correctly, or swiped after a normal time
        UNSURE = 3,     // known, but after long looking or with a self-corrected slip
        AGAIN = 4       // not known: "Lösung" was shown or a wrong letter remained
    };
    Q_ENUM(Rating)

    explicit LearningSession(QObject *parent = nullptr);

    void setPersons(const QVector<PersonData*> *persons) { m_persons = persons; }
    void setLetterModel(const LetterModel *letterModel) { m_letterModel = letterModel; }
    void setCardBoxSettings(const CardBoxSettings &settings) { m_settings = settings; }
    void setClock(std::function<qint64()> nowMs) { m_nowMs = std::move(nowMs); } // for tests
    void setAppActive(bool active); // time in the background doesn't count as looking

    Q_INVOKABLE void start();
    Q_INVOKABLE void clear();
    Q_INVOKABLE bool finishCurrent(); // rates the current card, returns true if known
    Q_INVOKABLE void next();          // shows the next card (from history or the front of the box)
    Q_INVOKABLE void back();          // returns to the previous card and undoes its rating
    // shows the name and clears the input, so the user can type it again for practice;
    // the card counts as not known in any case
    Q_INVOKABLE void showSolution();
    // after a wrong letter only backspace() is right - any other letter shows the solution;
    // a correct letter hides a shown solution again
    Q_INVOKABLE void typeLetter(const QString &letter);
    Q_INVOKABLE void backspace();

    PersonData *currentPerson() const;
    QString typed() const;
    bool solutionShown() const;   // "Lösung" was used for this card -> not known
    bool solutionVisible() const; // the name is on screen right now
    int corrections() const;      // self-corrected mistakes on the current card
    bool canGoBack() const { return m_index > 0; }
    QString targetName() const; // what the user is supposed to type for the current card
    bool typedIsCorrect() const; // typed text is a (case-insensitive) prefix of targetName()
    QStringList keys() const { return m_keys; }
    qint64 activeMs() const;     // time the current card has been on screen while the app was active
    QList<PersonData*> deck() const { return m_deck; } // card box, front = next card
    void setDeck(const QList<PersonData*> &deck) { m_deck = deck; }

signals:
    void currentChanged();
    void typedChanged();
    void solutionShownChanged();
    void keysChanged();

private:
    struct Entry {
        PersonData *person = nullptr;
        QString typed;
        bool solutionShown = false;
        bool solutionVisible = false;
        int corrections = 0;  // wrong letters the user took back on their own: known, but not safely
        Rating rating = Rating::NONE;
        // state before the rating, to undo it
        QList<PersonData*> deckBefore;
        int streakBefore = 0;
        QDateTime lastSeenBefore;
    };

    PersonData *pickNextPerson() const;
    Rating rate(const Entry &e) const;
    void applyRating(Entry &e, Rating r);
    void undoRating(Entry &e);
    void buildDeck();
    void restartClock();
    void updateKeys(const QString &pressed = QString(), int pressedIndex = -1);
    void emitCardChanged();

    const QVector<PersonData*> *m_persons = nullptr;
    const LetterModel *m_letterModel = nullptr;
    CardBoxSettings m_settings;
    QList<Entry> m_history;
    int m_index = -1;
    QStringList m_keys;
    QList<PersonData*> m_deck;

    std::function<qint64()> m_nowMs;
    qint64 m_cardStart = 0;
    qint64 m_pausedMs = 0;   // background time of the current card
    qint64 m_pauseStart = -1; // >= 0 while the app is in the background

    Q_PROPERTY(PersonData* currentPerson READ currentPerson NOTIFY currentChanged)
    Q_PROPERTY(QString typed READ typed NOTIFY typedChanged)
    Q_PROPERTY(bool typedIsCorrect READ typedIsCorrect NOTIFY typedChanged)
    Q_PROPERTY(QStringList keys READ keys NOTIFY keysChanged)
    Q_PROPERTY(bool solutionShown READ solutionShown NOTIFY solutionShownChanged)
    Q_PROPERTY(bool solutionVisible READ solutionVisible NOTIFY solutionShownChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY currentChanged)
    Q_PROPERTY(QString targetName READ targetName NOTIFY currentChanged)
};

#endif // LEARNINGSESSION_H
