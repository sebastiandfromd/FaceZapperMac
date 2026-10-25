#ifndef PERSONDATA_H
#define PERSONDATA_H
#include <QObject>
#include <QString>
#include <QMap>
#include <QDateTime>


class PersonData: public QObject
{
    Q_OBJECT

public:
    PersonData();

    enum class InteractionType {
        UNDEFINED = -1,
        SKIPPED = 0,
        CORRECT = 1,
        WRONG = 2
    };

    QString firstName() const;
    void setFirstName(const QString &firstName);

    QString familyName() const;
    void setFamilyName(const QString &familyName);

    QString picFileName() const;
    void setPicFileName(const QString &picFileName);

    qreal value() const;
    void setValue(const qreal &value);

    int skips() const;
    void setSkips(int newSkips);

    int fails() const;
    void setFails(int newFails);

    int wins() const;
    void setWins(int newWins);

    int uid() const;
    void setUid(int newUid);

    int streak() const;
    void setStreak(int newStreak);

    QDateTime lastSeen() const;
    void setLastSeen(const QDateTime &newLastSeen);

signals:
    void picFileNameChanged();
    void firstNameChanged();
    void familyNameChanged();

    void uidChanged();

private:
    int m_uid = -1;
    QString m_firstName = QString();
    QString m_familyName = QString();
    QString m_picFileName = QString();
    qreal m_value = 0;
    QMap<QDateTime,InteractionType> m_interactions;
    int m_skips = 0;  // number of skipped decisions
    int m_fails = 0;  // number of failed guesses
    int m_wins = 0;   // number of correct recognitions
    int m_streak = 0; // card box level: known in a row (reset when not known)
    QDateTime m_lastSeen;

    Q_PROPERTY(int uid READ uid WRITE setUid NOTIFY uidChanged)
    Q_PROPERTY(QString picFileName READ picFileName WRITE setPicFileName NOTIFY picFileNameChanged)
    Q_PROPERTY(QString firstName READ firstName WRITE setFirstName NOTIFY firstNameChanged)
    Q_PROPERTY(QString familyName READ familyName WRITE setFamilyName NOTIFY familyNameChanged)
};

#endif // PERSONDATA_H
