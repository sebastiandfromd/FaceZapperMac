#include "controller.h"

#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>
#include <QFile>
#include <QJsonDocument>
#include <QDebug>
#include <QDir>


bool Controller::saveAJsonFile(QString fileName, QString filePath, QJsonObject object) {
    QString fileNameAndPath = fileName;
    if (!filePath.isEmpty()) {
        if (filePath.right(1) != "/") fileNameAndPath.prepend("/");
        fileNameAndPath.prepend(filePath);
    }
    QFile saveFile(fileNameAndPath);
    QDir d(filePath);
    if (!d.mkpath(filePath)) {
        qWarning("Couldn't create or access path %ls when trying to write %ls.", qUtf16Printable(filePath), qUtf16Printable(fileName));
        return false;
    }
    if (!saveFile.open(QIODevice::WriteOnly)) {
        qWarning("Couldn't write to file %ls at %ls.", qUtf16Printable(fileName), qUtf16Printable(filePath));
        return false;
    }
    saveFile.write(QJsonDocument(object).toJson(QJsonDocument::Indented) );
    saveFile.close();
    return true;
}

QString Controller::delimiter() const
{
    qDebug()<<"Controller::delimiter() called, value is "<<m_delimiter;
    return m_delimiter;
}

void Controller::setDelimiter(const QString &newDelimiter)
{
    qDebug()<<"Controller::setDelimiter(...) called, value is "<< newDelimiter <<" instead of "<<m_delimiter;
    if (m_delimiter == newDelimiter)
        return;
    m_delimiter = newDelimiter;
    emit delimiterChanged();
}

QString Controller::replaceFrom() const
{
    qDebug()<<"Controller::replaceFrom() called, value is "<<m_replaceFrom;
    return m_replaceFrom;
}

void Controller::setReplaceFrom(const QString &newReplaceFrom)
{
    qDebug()<<"Controller::setReplaceFrom(...) called, value is "<< newReplaceFrom <<" instead of "<<m_replaceFrom;
    if (m_replaceFrom == newReplaceFrom)
        return;
    m_replaceFrom = newReplaceFrom;
    emit replaceFromChanged();
}

QString Controller::replaceTo() const
{
    qDebug()<<"Controller::replaceTo() called, value is "<<m_replaceTo;
    return m_replaceTo;
}

void Controller::setReplaceTo(const QString &newReplaceTo)
{
    qDebug()<<"Controller::setReplaceTo(...) called, value is "<< newReplaceTo <<" instead of "<<m_replaceTo;
    if (m_replaceTo == newReplaceTo)
        return;
    m_replaceTo = newReplaceTo;
    emit replaceToChanged();
}

int Controller::delimiterCounterIndex() const
{
    qDebug()<<"Controller::delimiterCounterIndex() called, value is "<<m_delimiterCounterIndex;
    return m_delimiterCounterIndex;
}

void Controller::setDelimiterCounterIndex(int newDelimiterCounterIndex)
{
    qDebug()<<"Controller::setDelimiterCounterIndex(...) called, value is "<< newDelimiterCounterIndex <<" instead of "<<m_delimiterCounterIndex;
    if (m_delimiterCounterIndex == newDelimiterCounterIndex)
        return;
    m_delimiterCounterIndex = newDelimiterCounterIndex;
    emit delimiterCounterIndexChanged();
}

bool Controller::firstNameFirst() const
{
    return m_firstNameFirst;
}

void Controller::setFirstNameFirst(bool newFirstNameFirst)
{
    if (m_firstNameFirst == newFirstNameFirst)
        return;
    m_firstNameFirst = newFirstNameFirst;
    emit firstNameFirstChanged();
}

int Controller::deleteNumberLocationIndex() const
{
    return m_deleteNumberLocationIndex;
}

void Controller::setDeleteNumberLocationIndex(int newDeleteNumberLocationIndex)
{
    if (m_deleteNumberLocationIndex == newDeleteNumberLocationIndex)
        return;
    m_deleteNumberLocationIndex = newDeleteNumberLocationIndex;
    emit deleteNumberLocationIndexChanged();
}

int Controller::deleteNumberCountIndex() const
{
    return m_deleteNumberCountIndex;
}

void Controller::setDeleteNumberCountIndex(int newDeleteNumberCountIndex)
{
    if (m_deleteNumberCountIndex == newDeleteNumberCountIndex)
        return;
    m_deleteNumberCountIndex = newDeleteNumberCountIndex;
    emit deleteNumberCountIndexChanged();
}

QString Controller::deleteCharsText() const
{
    return m_deleteCharsText;
}

void Controller::setDeleteCharsText(const QString &newDeleteCharsText)
{
    if (m_deleteCharsText == newDeleteCharsText)
        return;
    m_deleteCharsText = newDeleteCharsText;
    emit deleteCharsTextChanged();
}

int Controller::deleteCharsLocationIndex() const
{
    return m_deleteCharsLocationIndex;
}

void Controller::setDeleteCharsLocationIndex(int newDeleteCharsLocationIndex)
{
    if (m_deleteCharsLocationIndex == newDeleteCharsLocationIndex)
        return;
    m_deleteCharsLocationIndex = newDeleteCharsLocationIndex;
    emit deleteCharsLocationIndexChanged();
}

bool Controller::saveRecentFolders()
{
    QString settingsFolder = this->appDataPath();
    QString fileName = QStringLiteral("recentFolders.json");
    QJsonArray recentFoldersArray;
    for (auto &f : m_recentDirs) {
        QJsonObject folderObject;
        folderObject.insert("path", QJsonValue(f.path()));
        folderObject.insert("name", QJsonValue(f.name()));
        recentFoldersArray.append(folderObject);
    }
    QJsonObject foldersObject;
    foldersObject.insert("folders", recentFoldersArray);
    return saveAJsonFile(fileName, settingsFolder, foldersObject);
}

bool Controller::saveCurrentFolderData()
{
    QString settingsFolder = this->appDataPath();
    QString fileName = m_currentFolderData.name();
    QJsonArray personsArray;
    for (auto &p : m_currentPersonDataMap) {
        QJsonObject personObject;
        personObject.insert("firstName", QJsonValue(p->firstName()));
        personObject.insert("familyName", QJsonValue(p->familyName()));
        personObject.insert("picFileName", QJsonValue(p->picFileName()));
        personObject.insert("value", QJsonValue(p->value()));
        personObject.insert("skips", QJsonValue(p->skips()));
        personObject.insert("fails", QJsonValue(p->fails()));
        personObject.insert("wins", QJsonValue(p->wins()));
        personsArray.append(personObject);
    }
    QJsonObject folderObject;
    folderObject.insert("name", m_currentFolderData.name());
    folderObject.insert("persons", personsArray);
    return saveAJsonFile(fileName, settingsFolder,folderObject);
}
