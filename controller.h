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
#include "learningsession.h"
#include <QJsonObject>
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

        if (m_valuePersonMap.isEmpty()) {
            qDebug()<<"m_valuePersonMap.isEmpty(), NULLPTR returned!";
            return nullptr;
        }
        int r = int(QRandomGenerator::global()->bounded(m_valuePersonMap.count()));
        QMultiMapIterator<qreal, PersonData*> iter(m_valuePersonMap);
        iter.toFront();
        for(int i = 0; i<r; i++) {
            iter.next();
        }
        return iter.value();
    }
    Q_INVOKABLE QString currentFolderPath() { return m_currentFolderData.path(); }
    LearningSession *session() { return &m_session; }
    QString appDataPath() { return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation); }
    bool saveRecentFolders();
    static CardBoxSettings loadCardBoxSettings(); // from QSettings, see defaultSettings()

    // settings page: keys as stored in QSettings ("cardBox/...", "learning/...") with their defaults
    static QVariantMap defaultSettings();
    Q_INVOKABLE QVariant setting(const QString &key) const;
    Q_INVOKABLE void setSetting(const QString &key, const QVariant &value);
    Q_INVOKABLE void resetSettings();
    int flashDuration() const { return setting(QStringLiteral("learning/flashDuration")).toInt(); }

    // menu: forget what was learned in this folder / everything saved about it
    Q_INVOKABLE void resetTrainingData();
    Q_INVOKABLE void resetFolderData();
    // .faceZapperData in the picture folder: import settings, rows, group name, learning data
    Q_INVOKABLE bool saveFolderData();
    void loadFolder(const QString &path);
    QJsonObject importSettingsToJson() const;
    void applyImportSettings(const QJsonObject &settings);
    QJsonObject learningToJson() const;
    void applyLearning(const QJsonObject &learning);
    void clearPersons();
    void loadRecentFolders();
    void addRecentFolder(const QString &path, const QString &name);
    static QString folderDisplayName(const QString &pathOrUri);
    QString storageHint() const { return m_storageHint; }
    // the folder brought a .faceZapperData or was taken over ("Übernehmen") - only then data is saved
    bool folderKnown() const { return m_folderKnown; }

    bool saveAJsonFile(QString fileName, QString filePath, QJsonObject object);
    // fills the table with the folder's pictures; detectOrder: guess the name order from
    // the file names (only for folders opened the first time - otherwise it's saved)
    bool scanFolderToNameDerivationTable(const QString &filePath, bool detectOrder) {
        m_nameDerivationTable.clear();

        QDir dir(filePath);
        dir.setFilter(QDir::Files | QDir::Hidden | QDir::NoSymLinks);
        dir.setSorting(QDir::Size | QDir::Reversed);

        QFileInfoList list = dir.entryInfoList();
        QStringList imageTypes = { "png", "jpg", "gif", "bmp"};
        int imageCount = 0;
        int commaCount = 0;
        for (auto &f: list) {
            if (imageTypes.contains(f.suffix(), Qt::CaseInsensitive)) {
                m_nameDerivationTable.addRow(f.fileName(), f.completeBaseName());
                imageCount++;
                if (f.completeBaseName().contains(',')) commaCount++;
            }
        }
        if (detectOrder) {
            // mostly "Nachname, Vorname" -> family name first, otherwise "Vorname Nachname"
            setFirstNameFirst(commaCount * 2 <= imageCount);
            // split at the rightmost delimiter: with several words only the last one is
            // the family name (or the first name, if family name comes first without comma)
            setDelimiterCounterIndex(static_cast<int>(NameDerivationTable::DelimiterCounterOption::FIRST_FROM_RIGHT));
        }
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
                                                m_correctCase,
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
                                      m_correctCase,
                                      m_firstNameFirst);
    }
    void rebuildValuePersonMap();
    Q_INVOKABLE void takeOverTableContent();
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

    QString groupName() const;
    void setGroupName(const QString &newGroupName);

    bool correctCase() const;
    void setCorrectCase(bool newCorrectCase);

    QString solveAttempt() const;
    void setSolveAttempt(const QString &newSolveAttempt);

    QString groupFolder() const;
    void setGroupFolder(const QString &newGroupFolder);

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

    void groupNameChanged();

    void correctCaseChanged();

    void solveAttemptChanged();
    void groupFolderChanged();
    void storageHintChanged();
    void folderKnownChanged();
    void settingsChanged();

public slots:

private:
    QVector<PersonData*> m_personsVector;
    QMultiMap<qreal, PersonData*> m_valuePersonMap;

    QVector<FolderData> m_recentDirs;
    FaceImageProvider* m_imageProvider =  new FaceImageProvider();
    FolderData m_currentFolderData;
    NameDerivationTable m_nameDerivationTable;
    LearningSession m_session;
    LetterModel m_letterModel;
    QJsonObject m_folderData;   // what's in the current folder's .faceZapperData
    QString m_storageHint;      // set if the data couldn't be saved in the folder itself
    bool m_folderKnown = false; // .faceZapperData existed when the folder was opened
    QJsonObject m_defaultImportSettings; // to open a folder "as new" after resetting its data

    QString m_delimiter = " ";
    QString m_replaceFrom = "";
    QString m_replaceTo = "";
    bool m_isCaseSensitive = true; // for replacement
    bool m_correctCase = true; // will ensure that first letters in words are capitalized

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
    QString m_solveAttempt = QString();


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

    Q_PROPERTY(QString groupName READ groupName WRITE setGroupName NOTIFY groupNameChanged)
    Q_PROPERTY(bool correctCase READ correctCase WRITE setCorrectCase NOTIFY correctCaseChanged)
    Q_PROPERTY(QString solveAttempt READ solveAttempt WRITE setSolveAttempt NOTIFY solveAttemptChanged)
    Q_PROPERTY(QString groupFolder READ groupFolder WRITE setGroupFolder NOTIFY groupFolderChanged)
    Q_PROPERTY(LearningSession* session READ session CONSTANT)
    Q_PROPERTY(QString storageHint READ storageHint NOTIFY storageHintChanged)
    Q_PROPERTY(bool folderKnown READ folderKnown NOTIFY folderKnownChanged)
    Q_PROPERTY(int flashDuration READ flashDuration NOTIFY settingsChanged)
};

#endif // CONTROLLER_H
