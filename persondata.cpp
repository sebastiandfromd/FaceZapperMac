#include "persondata.h"
#include <QQmlEngine>

PersonData::PersonData(): QObject(nullptr)
{
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
}

QString PersonData::firstName() const
{
    return m_firstName;
}

void PersonData::setFirstName(const QString &firstName)
{
    m_firstName = firstName;
}

QString PersonData::familyName() const
{
    return m_familyName;
}

void PersonData::setFamilyName(const QString &familyName)
{
    m_familyName = familyName;
}

QString PersonData::picFileName() const
{
    return m_picFileName;
}

void PersonData::setPicFileName(const QString &picFileName)
{
    m_picFileName = picFileName;
}

qint64 PersonData::value() const
{
    return m_value;
}

void PersonData::setValue(const qint64 &value)
{
    m_value = value;
}

int PersonData::skips() const
{
    return m_skips;
}

void PersonData::setSkips(int newSkips)
{
    m_skips = newSkips;
}

int PersonData::fails() const
{
    return m_fails;
}

void PersonData::setFails(int newFails)
{
    m_fails = newFails;
}

int PersonData::wins() const
{
    return m_wins;
}

void PersonData::setWins(int newWins)
{
    m_wins = newWins;
}
