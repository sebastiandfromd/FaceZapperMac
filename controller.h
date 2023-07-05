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

public:
    explicit Controller(QObject *parent = nullptr);

    void init(QQmlApplicationEngine *engine);

    Q_INVOKABLE PersonData* nextPersonData() {

        if (m_currentPersonDataMap.isEmpty()) {
//            qDebug()<<"m_currentPersonDataMap.isEmpty(), NULLPTR returned!";
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
    QString appDataPath() { return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation); }
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
                m_nameDerivationTable.addRow(f.fileName(), f.baseName());
            }
        }
        this->runNameDerivation();
        return true;
    }

    Q_INVOKABLE void runNameDerivation() {
        m_nameDerivationTable.runNameDerivation(static_cast<NameDerivationTable::DeletionLocationOption>(m_deleteNumberLocationIndex),
                                                m_deleteNumberCountIndex,
                                                static_cast<NameDerivationTable::DeletionLocationOption>(m_deleteCharsLocationIndex),
                                                m_deleteCharsText,
                                                m_replaceFrom,
                                                m_replaceTo,
                                                m_isCaseSensitive ? Qt::CaseSensitive : Qt::CaseInsensitive,
                                                m_delimiter,
                                                static_cast<NameDerivationTable::DelimiterCounterOption>(m_delimiterCounterIndex),
                                                m_firstNameFirst
                                                );
    }
    Q_INVOKABLE void nameDerivationTableClicked(int row, int column) {
        m_nameDerivationTable.clicked(row, column, static_cast<NameDerivationTable::DeletionLocationOption>(m_deleteNumberLocationIndex),
                                      m_deleteNumberCountIndex,
                                      static_cast<NameDerivationTable::DeletionLocationOption>(m_deleteCharsLocationIndex),
                                      m_deleteCharsText,
                                      m_replaceFrom,
                                      m_replaceTo,
                                      m_isCaseSensitive ? Qt::CaseSensitive : Qt::CaseInsensitive,
                                      m_delimiter,
                                      static_cast<NameDerivationTable::DelimiterCounterOption>(m_delimiterCounterIndex),
                                      m_firstNameFirst);
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

    bool isCaseSensitive() const;
    void setIsCaseSensitive(bool newIsCaseSensitive);

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

    void isCaseSensitiveChanged();

private:
    QMultiMap<qint64,PersonData*> m_currentPersonDataMap;
    QVector<FolderData> m_recentDirs;
    FaceImageProvider* m_imageProvider =  new FaceImageProvider();
    FolderData m_currentFolderData;
    NameDerivationTable m_nameDerivationTable;

    QString m_delimiter = " ";
    QString m_replaceFrom = "";
    QString m_replaceTo = "";
    bool m_isCaseSensitive = true;

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
    Q_PROPERTY(int delimiterCounterIndex READ delimiterCounterIndex WRITE setDelimiterCounterIndex NOTIFY delimiterCounterIndexChanged)
    Q_PROPERTY(QString replaceFrom READ replaceFrom WRITE setReplaceFrom NOTIFY replaceFromChanged)
    Q_PROPERTY(QString replaceTo READ replaceTo WRITE setReplaceTo NOTIFY replaceToChanged)
    Q_PROPERTY(bool firstNameFirst READ firstNameFirst WRITE setFirstNameFirst NOTIFY firstNameFirstChanged)
    Q_PROPERTY(int deleteNumberLocationIndex READ deleteNumberLocationIndex WRITE setDeleteNumberLocationIndex NOTIFY deleteNumberLocationIndexChanged)
    Q_PROPERTY(int deleteNumberCountIndex READ deleteNumberCountIndex WRITE setDeleteNumberCountIndex NOTIFY deleteNumberCountIndexChanged)
    Q_PROPERTY(QString deleteCharsText READ deleteCharsText WRITE setDeleteCharsText NOTIFY deleteCharsTextChanged)
    Q_PROPERTY(int deleteCharsLocationIndex READ deleteCharsLocationIndex WRITE setDeleteCharsLocationIndex NOTIFY deleteCharsLocationIndexChanged)
    Q_PROPERTY(bool isCaseSensitive READ isCaseSensitive WRITE setIsCaseSensitive NOTIFY isCaseSensitiveChanged)
};

#endif // CONTROLLER_H
