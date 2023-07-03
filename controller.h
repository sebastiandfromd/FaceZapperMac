#ifndef CONTROLLER_H
#define CONTROLLER_H

#include <QObject>
#include <QMap>
#include <QSharedPointer>
#include <QStandardPaths>
#include "namederivationtable.h"
#include "persondata.h"
#include <QQmlApplicationEngine>
#include "folderdata.h"
#include <QDebug>
#include "faceimageprovider.h"
#include <QDir>
#include <QQuickView>
#include <QQmlContext>
#include <QRandomGenerator>


class Controller : public QObject
{
    Q_OBJECT
//    Q_PROPERTY(QString delimiter READ delimiter WRITE setDelimiter NOTIFY delimiterChanged)

public:
    explicit Controller(QObject *parent = nullptr) : QObject(parent){
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

    void init(QQmlApplicationEngine *engine) {
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

    Q_INVOKABLE PersonData* nextPersonData() {

        if (m_currentPersonDataMap.isEmpty()) {
            qDebug()<<"m_currentPersonDataMap.isEmpty(), NULLPTR returned!";
            return nullptr;
        }
        int r = QRandomGenerator::global()->bounded(1,m_currentPersonDataMap.count()-1);
        QMultiMapIterator<qint64, PersonData*> iter(m_currentPersonDataMap);
        iter.toFront();
        for(int i = 0; i<r; i++) {
            iter.next();
        }
        return iter.value();
    }
    Q_INVOKABLE QString currentFolderPath() { return m_currentFolderData.path(); }
    QString appDataPath() {
        return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    }
    bool saveRecentFolders();
    bool saveCurrentFolderData();

    bool saveAJsonFile(QString fileName, QString filePath, QJsonObject object);
    bool scanFolderToCurrent(QString fileName, QString filePath) {
        QDir dir(filePath);
        dir.setFilter(QDir::Files | QDir::Hidden | QDir::NoSymLinks);
        dir.setSorting(QDir::Size | QDir::Reversed);

        QFileInfoList list = dir.entryInfoList();
        QStringList imageTypes = { "png", "jpg", "gif", "bmp"};
        for (auto &f: list) {
            if (imageTypes.contains(f.suffix())) {
//                PersonData* p = new PersonData();
//                p->setFirstName(f.baseName());
//                p->setPicFileName(f.fileName());
//                m_currentPersonDataMap.insert(1,p);

                m_nameDerivationTable.addPerson(f.fileName(), f.baseName());
            }
        }
        this->runNameDerivation();
//        m_nameDerivationTable.runNameDerivation(m_delimiter, m_replaceFrom, m_replaceTo,
//                                                m_delimiterCounterIndex, m_firstNameFirst);
        return true;
    }

    Q_INVOKABLE void runNameDerivation() {
        m_nameDerivationTable.runNameDerivation(static_cast<NameDerivationTable::DeletionLocationOption>(m_deleteNumberLocationIndex),
                                                m_deleteNumberCountIndex,
                                                static_cast<NameDerivationTable::DeletionLocationOption>(m_deleteCharsLocationIndex),
                                                m_deleteCharsText,
                                                m_replaceFrom,
                                                m_replaceTo,
                                                m_delimiter,
                                                static_cast<NameDerivationTable::DelimiterCounterOption>(m_delimiterCounterIndex),
                                                m_firstNameFirst
                                                );
    }

    QString delimiter() const;
    void setDelimiter(const QString &newDelimiter);

    QString replaceFrom() const;
    void setReplaceFrom(const QString &newReplaceFrom);

    QString replaceTo() const;
    void setReplaceTo(const QString &newReplaceTo);

    int delimiterCounterIndex() const;
    void setDelimiterCounterIndex(int newDelimiterCounterIndex);

    bool firstNameFirst() const;
    void setFirstNameFirst(bool newFirstNameFirst);

    int deleteNumberLocationIndex() const;
    void setDeleteNumberLocationIndex(int newDeleteNumberLocationIndex);

    int deleteNumberCountIndex() const;
    void setDeleteNumberCountIndex(int newDeleteNumberCountIndex);

    QString deleteCharsText() const;
    void setDeleteCharsText(const QString &newDeleteCharsText);

    int deleteCharsLocationIndex() const;
    void setDeleteCharsLocationIndex(int newDeleteCharsLocationIndex);

signals:

    void delimiterChanged();

    void replaceFromChanged();

    void replaceToChanged();

    void delimiterCounterIndexChanged();

    void firstNameFirstChanged();

    void deleteNumberLocationIndexChanged();

    void deleteNumberCountIndexChanged();

    void deleteCharsTextChanged();

    void deleteCharsLocationIndexChanged();

private:
    QMultiMap<qint64,PersonData*> m_currentPersonDataMap;
    QVector<FolderData> m_recentDirs;
    FaceImageProvider* m_imageProvider =  new FaceImageProvider();
    FolderData m_currentFolderData;
    NameDerivationTable m_nameDerivationTable;

    QString m_delimiter = ", ";
    QString m_replaceFrom = "^#";
    QString m_replaceTo = "";
    int m_delimiterCounterIndex = static_cast<int>(NameDerivationTable::DelimiterCounterOption::MIDDLE_LEFT);
    // specifies, which delimiter (if more than one is present) shall be used

    int m_deleteNumberLocationIndex = static_cast<int>(NameDerivationTable::DeletionLocationOption::LEFT);
    // specifies, where a given number of chars shall be deleted

    int m_deleteNumberCountIndex = 0;
    // specifies this number of chars to be deleted

    int m_deleteCharsLocationIndex = static_cast<int>(NameDerivationTable::DeletionLocationOption::SIDES);
    // specifies, where special chars shall be deleted

    QString m_deleteCharsText = " $%&()=`´+~'#<>|.-_{[]}@0123456789";
    // specifies, which special chars shall be deleted


    bool m_firstNameFirst = false;


    Q_PROPERTY(QString delimiter READ delimiter WRITE setDelimiter NOTIFY delimiterChanged)
    Q_PROPERTY(QString replaceFrom READ replaceFrom WRITE setReplaceFrom NOTIFY replaceFromChanged)
    Q_PROPERTY(QString replaceTo READ replaceTo WRITE setReplaceTo NOTIFY replaceToChanged)
    Q_PROPERTY(int delimiterCounterIndex READ delimiterCounterIndex WRITE setDelimiterCounterIndex NOTIFY delimiterCounterIndexChanged)
    Q_PROPERTY(bool firstNameFirst READ firstNameFirst WRITE setFirstNameFirst NOTIFY firstNameFirstChanged)
    Q_PROPERTY(int deleteNumberLocationIndex READ deleteNumberLocationIndex WRITE setDeleteNumberLocationIndex NOTIFY deleteNumberLocationIndexChanged)
    Q_PROPERTY(int deleteNumberCountIndex READ deleteNumberCountIndex WRITE setDeleteNumberCountIndex NOTIFY deleteNumberCountIndexChanged)
    Q_PROPERTY(QString deleteCharsText READ deleteCharsText WRITE setDeleteCharsText NOTIFY deleteCharsTextChanged)
    Q_PROPERTY(int deleteCharsLocationIndex READ deleteCharsLocationIndex WRITE setDeleteCharsLocationIndex NOTIFY deleteCharsLocationIndexChanged)
};

#endif // CONTROLLER_H
