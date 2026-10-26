#include "controller.h"

#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>
#include <QFile>
#include <QJsonDocument>
#include <QDebug>
#include <QDir>
#include <QUrl>
#include <QRegularExpression>
#include <QGuiApplication>
#include <QSettings>
#include "folderstore.h"


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

void Controller::rebuildValuePersonMap(){
    m_valuePersonMap.clear();
    for(auto &p : m_personsVector) {
        m_valuePersonMap.insert(p->value(), p);
    }
}

void Controller::takeOverTableContent()
{
    qDebug()<<"takeOverTableContent";
    // keep what was learned so far (also for cards not in this run)
    if (!m_personsVector.isEmpty()) m_folderData.insert("learning", learningToJson());
    clearPersons();
    m_nameDerivationTable.fillPersonDataMap(&m_personsVector);
    applyLearning(m_folderData.value("learning").toObject());
    m_imageProvider->setFolder(m_currentFolderData.path());
    QStringList names;
    for (const auto *p : std::as_const(m_personsVector))
        names << p->firstName() + u' ' + p->familyName();
    m_letterModel.setFolderNames(names);
    rebuildValuePersonMap();
    if (!m_folderKnown) {
        m_folderKnown = true; // "Übernehmen" is what makes a folder one that keeps its data
        emit folderKnownChanged();
    }
    saveFolderData();
}

void Controller::clearPersons()
{
    m_session.clear(); // its history and card box point to the persons deleted below
    m_session.setDeck({});
    qDeleteAll(m_personsVector);
    m_personsVector.clear();
    m_valuePersonMap.clear();
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

QString Controller::groupName() const
{
    return m_currentFolderData.name();
}

void Controller::setGroupName(const QString &newGroupName)
{
    if ( m_currentFolderData.name() == newGroupName)
        return;
    m_currentFolderData.setName(newGroupName);
    emit groupNameChanged();
}

bool Controller::correctCase() const
{
    return m_correctCase;
}

void Controller::setCorrectCase(bool newCorrectCase)
{
    if (m_correctCase == newCorrectCase)
        return;
    m_correctCase = newCorrectCase;
    emit correctCaseChanged();
}

QString Controller::solveAttempt() const
{
    return m_solveAttempt;
}

void Controller::setSolveAttempt(const QString &newSolveAttempt)
{
    if (m_solveAttempt == newSolveAttempt)
        return;
    m_solveAttempt = newSolveAttempt;
    qDebug()<< "so far, user has made this input :"<<newSolveAttempt;
    emit solveAttemptChanged();
}

QString Controller::groupFolder() const
{
    return m_currentFolderData.path();
}

void Controller::setGroupFolder(const QString &newGroupFolder)
{
    // FolderDialog delivers a URL ("file:///D:/..."), QDir needs a local path
    const QUrl url(newGroupFolder);
    const QString path = url.isLocalFile() ? url.toLocalFile() : newGroupFolder;
    if (m_currentFolderData.path() == path)
        return;
    saveFolderData(); // keep the work on the previous folder
    FolderStore::takePersistableWritePermission(path);
    loadFolder(path);
}

QString Controller::folderDisplayName(const QString &pathOrUri)
{
    // (a plain "D:/..." path parses as scheme "d", so check for "://" instead of the scheme)
    const QUrl url(pathOrUri);
    if (url.isLocalFile() || !pathOrUri.contains("://"))
        return QDir(url.isLocalFile() ? url.toLocalFile() : pathOrUri).dirName();
    // Android content URI, e.g. ".../tree/primary%3ADCIM%2F09B" -> "09B"
    const QStringList parts = url.path(QUrl::FullyDecoded).split(QRegularExpression("[/:]"), Qt::SkipEmptyParts);
    return parts.isEmpty() ? pathOrUri : parts.last();
}

void Controller::loadFolder(const QString &path)
{
    clearPersons(); // learning data of the previous folder must not end up in this one
    m_currentFolderData.setPath(path);
    emit groupFolderChanged();
    m_folderData = FolderStore::load(path);
    // a folder opened before brings its settings (name order included) - no guessing then
    const bool known = !m_folderData.isEmpty();
    // a new folder starts from the defaults, not with the previous folder's settings
    applyImportSettings(known ? m_folderData.value("import").toObject() : m_defaultImportSettings);
    scanFolderToNameDerivationTable(path, !known);
    if (known) m_nameDerivationTable.applyRows(m_folderData.value("rows").toArray());
    runNameDerivation();
    const QString savedName = m_folderData.value("groupName").toString();
    setGroupName(savedName.isEmpty() ? folderDisplayName(path) : savedName);
    addRecentFolder(path, groupName());
    m_folderKnown = known;
    emit folderKnownChanged();
}



Controller::Controller(QObject *parent) : QObject(parent){
    m_session.setPersons(&m_personsVector);
    if (!m_letterModel.load(QStringLiteral(":/letterstats.json")))
        qWarning("Couldn't load letter statistics, the keyboard falls back to the folder's names.");
    m_session.setLetterModel(&m_letterModel);
    m_session.setCardBoxSettings(loadCardBoxSettings());
    // time the app spends in the background doesn't count as looking at a face
    connect(qGuiApp, &QGuiApplication::applicationStateChanged, this, [this](Qt::ApplicationState state) {
        m_session.setAppActive(state == Qt::ApplicationActive);
    });
    // save after every rating and when the app ends
    connect(&m_session, &LearningSession::rated, this, &Controller::saveFolderData);
    connect(qGuiApp, &QCoreApplication::aboutToQuit, this, &Controller::saveFolderData);

    m_defaultImportSettings = importSettingsToJson(); // before any folder changes them

    // start with the folder used last
    loadRecentFolders();
    if (!m_recentDirs.isEmpty())
        loadFolder(m_recentDirs.first().path());
}

void Controller::init(QQmlApplicationEngine *engine) {
    qmlRegisterType<Controller>("de.herrdiel.facezapper", 1, 0, "Controller");
    qmlRegisterType<PersonData>("de.herrdiel.facezapper", 1, 0, "PersonData");
    qmlRegisterType<NameDerivationTable>("de.herrdiel.facezapper", 1, 0, "NameDerivationTable");
    qmlRegisterType<FolderData>("de.herrdiel.facezapper", 1, 0, "FolderData");
    qmlRegisterUncreatableType<LearningSession>("de.herrdiel.facezapper", 1, 0, "LearningSession",
                                                "LearningSession is provided by controller.session");
    engine->addImageProvider(QLatin1String("faceProvider"), m_imageProvider);

    auto view = new QQuickView(engine, nullptr);
    QQmlContext *ctxt = view->rootContext();

    ctxt->setContextProperty("controller", this);
    ctxt->setContextProperty("nameDerivationTable", &m_nameDerivationTable);
    ctxt->setContextProperty("currentFolderData",  QVariant::fromValue(m_currentFolderData));
}

// where the app-wide settings live (registry on Windows, shared prefs on Android)
static const QString settingsOrg = QStringLiteral("herrdiel");
static const QString settingsApp = QStringLiteral("FaceZapper");

QVariantMap Controller::defaultSettings()
{
    const CardBoxSettings c; // its member initializers are the defaults
    return {
        {"cardBox/easySeconds", c.easySeconds},
        {"cardBox/unsureSeconds", c.unsureSeconds},
        {"cardBox/easyFactor", c.easyFactor},
        {"cardBox/goodFactor", c.goodFactor},
        {"cardBox/unsureOffset", c.unsureOffset},
        {"cardBox/againOffset", c.againOffset},
        {"cardBox/learnedStreak", c.learnedStreak},
        {"cardBox/newCardInterval", c.newCardInterval},
        {"learning/targetMode", c.targetMode},
        {"learning/flashDuration", 500},
        {"ui/expertMode", false}, // import screen: show all options for deriving names from file names
    };
}

CardBoxSettings Controller::loadCardBoxSettings()
{
    QSettings s(settingsOrg, settingsApp);
    const QVariantMap d = defaultSettings();
    auto value = [&s, &d](const char *key) { return s.value(QLatin1String(key), d.value(QLatin1String(key))); };
    CardBoxSettings c;
    c.easySeconds = value("cardBox/easySeconds").toDouble();
    c.unsureSeconds = value("cardBox/unsureSeconds").toDouble();
    c.easyFactor = value("cardBox/easyFactor").toInt();
    c.goodFactor = value("cardBox/goodFactor").toInt();
    c.unsureOffset = value("cardBox/unsureOffset").toInt();
    c.againOffset = value("cardBox/againOffset").toInt();
    c.learnedStreak = value("cardBox/learnedStreak").toInt();
    c.newCardInterval = value("cardBox/newCardInterval").toInt();
    c.targetMode = value("learning/targetMode").toInt();
    return c;
}

QVariant Controller::setting(const QString &key) const
{
    return QSettings(settingsOrg, settingsApp).value(key, defaultSettings().value(key));
}

void Controller::setSetting(const QString &key, const QVariant &value)
{
    if (!defaultSettings().contains(key) || setting(key) == value) return;
    QSettings s(settingsOrg, settingsApp);
    s.setValue(key, value);
    s.sync();
    m_session.setCardBoxSettings(loadCardBoxSettings());
    emit settingsChanged();
}

void Controller::resetSettings()
{
    QSettings s(settingsOrg, settingsApp);
    for (const QString &key : defaultSettings().keys())
        if (!key.startsWith(QLatin1String("ui/"))) s.remove(key); // screen layout isn't a learning setting

    s.sync();
    m_session.setCardBoxSettings(loadCardBoxSettings());
    emit settingsChanged();
}

void Controller::resetTrainingData()
{
    // only what was learned - names and import settings stay
    const bool learning = m_session.currentPerson() != nullptr;
    m_session.clear();
    m_session.setDeck({}); // new random order
    for (PersonData *p : std::as_const(m_personsVector)) {
        p->setStreak(0);
        p->setWins(0);
        p->setFails(0);
        p->setSkips(0);
        p->setLastSeen(QDateTime());
    }
    m_folderData.remove("learning");
    if (learning) m_session.start();
    saveFolderData();
}

void Controller::resetFolderData()
{
    // forget everything about this folder and open it as if for the first time
    const QString path = m_currentFolderData.path();
    if (path.isEmpty()) return;
    clearPersons();
    FolderStore::remove(path);
    m_folderData = QJsonObject();
    loadFolder(path); // without data: default settings and automatic detection
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

void Controller::loadRecentFolders()
{
    QFile f(appDataPath() + QStringLiteral("/recentFolders.json"));
    if (!f.open(QIODevice::ReadOnly)) return;
    const QJsonArray folders = QJsonDocument::fromJson(f.readAll()).object().value("folders").toArray();
    m_recentDirs.clear();
    for (const QJsonValue &v : folders) {
        FolderData fd;
        fd.setPath(v.toObject().value("path").toString());
        fd.setName(v.toObject().value("name").toString());
        if (!fd.path().isEmpty()) m_recentDirs << fd;
    }
}

void Controller::addRecentFolder(const QString &path, const QString &name)
{
    m_recentDirs.removeIf([&path](const FolderData &f) { return f.path() == path; });
    FolderData fd;
    fd.setPath(path);
    fd.setName(name);
    m_recentDirs.prepend(fd);
    while (m_recentDirs.size() > 10) m_recentDirs.removeLast();
    saveRecentFolders();
    emit recentFoldersChanged();
}

QVariantList Controller::recentFolders() const
{
    QVariantList list;
    for (const FolderData &f : m_recentDirs) {
        // local folders that are gone are left out (Android content:// folders can't be checked cheaply)
        if (!f.path().contains(QLatin1String("://")) && !QDir(f.path()).exists()) continue;
        list << QVariantMap{{"name", f.name()}, {"path", f.path()}};
    }
    return list;
}

QJsonObject Controller::importSettingsToJson() const
{
    QJsonObject s;
    s.insert("deleteNumberLocation", m_deleteNumberLocationIndex);
    s.insert("deleteNumberCount", m_deleteNumberCountIndex);
    s.insert("deleteCharsLocation", m_deleteCharsLocationIndex);
    s.insert("deleteCharsText", m_deleteCharsText);
    s.insert("replaceFrom", m_replaceFrom);
    s.insert("replaceTo", m_replaceTo);
    s.insert("caseSensitive", m_isCaseSensitive);
    s.insert("delimiter", m_delimiter);
    s.insert("delimiterCounter", m_delimiterCounterIndex);
    s.insert("firstNameFirst", m_firstNameFirst);
    s.insert("correctCase", m_correctCase);
    return s;
}

void Controller::applyImportSettings(const QJsonObject &s)
{
    // through the setters, so the controls on the import screen follow
    setDeleteNumberLocationIndex(s.value("deleteNumberLocation").toInt(m_deleteNumberLocationIndex));
    setDeleteNumberCountIndex(s.value("deleteNumberCount").toInt(m_deleteNumberCountIndex));
    setDeleteCharsLocationIndex(s.value("deleteCharsLocation").toInt(m_deleteCharsLocationIndex));
    setDeleteCharsText(s.value("deleteCharsText").toString(m_deleteCharsText));
    setReplaceFrom(s.value("replaceFrom").toString(m_replaceFrom));
    setReplaceTo(s.value("replaceTo").toString(m_replaceTo));
    setIsCaseSensitive(s.value("caseSensitive").toBool(m_isCaseSensitive));
    setDelimiter(s.value("delimiter").toString(m_delimiter));
    setDelimiterCounterIndex(s.value("delimiterCounter").toInt(m_delimiterCounterIndex));
    setFirstNameFirst(s.value("firstNameFirst").toBool(m_firstNameFirst));
    setCorrectCase(s.value("correctCase").toBool(m_correctCase));
}

QJsonObject Controller::learningToJson() const
{
    // start from the saved cards, so cards that aren't in the current run (excluded,
    // file temporarily gone) keep their history
    QJsonObject cards = m_folderData.value("learning").toObject().value("cards").toObject();
    for (const PersonData *p : m_personsVector) {
        QJsonObject c;
        c.insert("streak", p->streak());
        c.insert("wins", p->wins());
        c.insert("fails", p->fails());
        c.insert("skips", p->skips());
        if (p->lastSeen().isValid()) c.insert("lastSeen", p->lastSeen().toString(Qt::ISODate));
        cards.insert(p->picFileName(), c);
    }
    QJsonArray deck;
    for (const PersonData *p : m_session.deck())
        deck.append(p->picFileName());
    QJsonObject learning;
    learning.insert("cards", cards);
    learning.insert("deck", deck.isEmpty() ? m_folderData.value("learning").toObject().value("deck") : deck);
    return learning;
}

void Controller::applyLearning(const QJsonObject &learning)
{
    const QJsonObject cards = learning.value("cards").toObject();
    QHash<QString, PersonData*> byFile;
    for (PersonData *p : std::as_const(m_personsVector)) {
        byFile.insert(p->picFileName(), p);
        const QJsonObject c = cards.value(p->picFileName()).toObject();
        if (c.isEmpty()) continue; // new picture: new card
        p->setStreak(c.value("streak").toInt());
        p->setWins(c.value("wins").toInt());
        p->setFails(c.value("fails").toInt());
        p->setSkips(c.value("skips").toInt());
        p->setLastSeen(QDateTime::fromString(c.value("lastSeen").toString(), Qt::ISODate));
    }
    // card box order; new pictures are put in at random places when learning starts
    QList<PersonData*> deck;
    for (const QJsonValue &v : learning.value("deck").toArray())
        if (PersonData *p = byFile.value(v.toString())) deck << p;
    m_session.setDeck(deck);
}

bool Controller::saveFolderData()
{
    const QString path = m_currentFolderData.path();
    // only a folder that was taken over ("Übernehmen") or already has data gets written -
    // just looking at a folder (and its automatic detection) leaves no file behind
    if (path.isEmpty() || !m_folderKnown) return false;
    QJsonObject data;
    data.insert("version", 1);
    data.insert("groupName", m_currentFolderData.name());
    data.insert("import", importSettingsToJson());
    data.insert("rows", m_nameDerivationTable.rowsToJson());
    data.insert("learning", m_personsVector.isEmpty() ? m_folderData.value("learning") : learningToJson());
    m_folderData = data;
    const bool inFolder = FolderStore::save(path, data);
    // a renamed group shows its new name under "Letzte Gruppen"
    for (FolderData &f : m_recentDirs) {
        if (f.path() == path && f.name() != m_currentFolderData.name()) {
            f.setName(m_currentFolderData.name());
            saveRecentFolders();
            emit recentFoldersChanged();
        }
    }
    const QString hint = inFolder ? QString()
                                  : tr("Daten konnten nicht im Bilderordner gespeichert werden, sie liegen in der App.");
    if (hint != m_storageHint) {
        m_storageHint = hint;
        emit storageHintChanged();
    }
    return inFolder;
}
