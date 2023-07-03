#ifndef PERSONDATA_H
#define PERSONDATA_H
#include <QObject>
#include <QString>
#include <QMap>
#include <QDateTime>


class PersonData: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString picFileName READ picFileName WRITE setPicFileName NOTIFY picFileNameChanged)
    Q_PROPERTY(QString firstName READ firstName WRITE setFirstName NOTIFY firstNameChanged)
    Q_PROPERTY(QString familyName READ familyName WRITE setFamilyName NOTIFY familyNameChanged)

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

    qint64 value() const;
    void setValue(const qint64 &value);

    int skips() const;
    void setSkips(int newSkips);

    int fails() const;
    void setFails(int newFails);

    int wins() const;
    void setWins(int newWins);

signals:
    void picFileNameChanged();
    void firstNameChanged();
    void familyNameChanged();

private:

    QString m_firstName = QString();
    QString m_familyName = QString();
    QString m_picFileName = QString();
    qint64 m_value = 0;
    QMap<QDateTime,InteractionType> m_interactions;
    int m_skips = 0;  // number of skipped decisions
    int m_fails = 0;  // number of failed guesses
    int m_wins = 0;   // number of correct recognitions

};

#endif // PERSONDATA_H
