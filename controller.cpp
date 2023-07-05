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
    return m_delimiter;
}

void Controller::setDelimiter(const QString &newDelimiter)
{
    if (m_delimiter == newDelimiter)
        return;
    m_delimiter = newDelimiter;
    emit delimiterChanged();
}

QString Controller::replaceFrom() const
{
    return m_replaceFrom;
}

void Controller::setReplaceFrom(const QString &newReplaceFrom)
{
    if (m_replaceFrom == newReplaceFrom)
        return;
    m_replaceFrom = newReplaceFrom;
    emit replaceFromChanged();
}

QString Controller::replaceTo() const
{
    return m_replaceTo;
}

void Controller::setReplaceTo(const QString &newReplaceTo)
{
    if (m_replaceTo == newReplaceTo)
        return;
    m_replaceTo = newReplaceTo;
    emit replaceToChanged();
}

int Controller::delimiterCounterIndex() const
{
    return m_delimiterCounterIndex;
}

void Controller::setDelimiterCounterIndex(int newDelimiterCounterIndex)
{
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

bool Controller::isCaseSensitive() const
{
    return m_isCaseSensitive;
}

void Controller::setIsCaseSensitive(bool newIsCaseSensitive)
{
    if (m_isCaseSensitive == newIsCaseSensitive)
        return;
    m_isCaseSensitive = newIsCaseSensitive;
    emit isCaseSensitiveChanged();
}

Controller::Controller(QObject *parent) : QObject(parent){
    m_imageProvider = new FaceImageProvider();

    //        PersonData* pd1 = new PersonData();
    //        pd1->setFirstName("Harry");
    //        pd1->setFamilyName("Potter");
    //        pd1->setPicFileName("harry potter.jpg");
    //        pd1->setValue(1);
    //        m_currentPersonDataMap.insert(pd1->value(), pd1);

    //        PersonData* pd2 = new PersonData();
    //        pd2->setFirstName("Hermine");
    //        pd2->setFamilyName("Granger");
    //        pd2->setPicFileName("hermine granger.jpg");
    //        pd2->setValue(0);
    //        m_currentPersonDataMap.insert(pd2->value(), pd2);

    //        PersonData* pd3 = new PersonData();
    //        pd3->setFirstName("Ronald");
    //        pd3->setFamilyName("Weasley");
    //        pd3->setPicFileName("ronald weasley.jpg");
    //        pd3->setValue(-1);
    //        m_currentPersonDataMap.insert(pd3->value(), pd3);

    FolderData f0;
    f0.setPath("C:/Program Files (x86)/ClassInTouch/beispieldaten/bilder");
    f0.setName("7b bilder");
    FolderData f1;
    f1.setPath("C:/Users/user/cit/ressources/icons");
    f1.setName("7b Icons");
    FolderData f2;
    f2.setPath("C:/Users/user/cit2/classintouch-2/ClassInTouch2/resources");
    f2.setName("8c resources");
    FolderData f3;
    f3.setPath("C:/Users/user");
    f3.setName("Q2 user");
    m_recentDirs << f0 << f1 << f2 << f3;

    saveRecentFolders();

    m_currentFolderData.setName(f0.name());
    m_currentFolderData.setPath(f0.path());

    scanFolderToCurrent("name", "C:/Program Files (x86)/ClassInTouch/beispieldaten/bilder");
    saveCurrentFolderData();
    //        QMultiMapIterator<qint64, PersonData*> iter(m_currentPersonDataMap);
    //        iter.toFront();
    //        for(int i = 0; i<m_currentPersonDataMap.count(); i++) {
    //            qDebug()<<i<<": "<<iter.next().value()->picFileName();
    //        }
    //        qDebug()<<"-----------------------------------------------------------";
}

void Controller::init(QQmlApplicationEngine *engine) {
    qmlRegisterType<Controller>("de.herrdiel.facezapper", 1, 0, "Controller");
    qmlRegisterType<PersonData>("de.herrdiel.facezapper", 1, 0, "PersonData");
    qmlRegisterType<NameDerivationTable>("de.herrdiel.facezapper", 1, 0, "NameDerivationTable");
    qmlRegisterType<FolderData>("de.herrdiel.facezapper", 1, 0, "FolderData");
    engine->addImageProvider(QLatin1String("faceProvider"), m_imageProvider);



    auto view = new QQuickView(engine, nullptr);
    QQmlContext *ctxt = view->rootContext();

    ctxt->setContextProperty("controller", this);
    ctxt->setContextProperty("nameDerivationTable", &m_nameDerivationTable);
    ctxt->setContextProperty("currentFolderData",  QVariant::fromValue(m_currentFolderData));
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
