#include "folderstore.h"
#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QStandardPaths>
#include <QDebug>
#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniEnvironment>
#include <QJniObject>
#endif

namespace {

QString folderFile(const QString &folder)
{
    return folder + u'/' + QLatin1String(FolderStore::dataFileName);
}

QString fallbackFile(const QString &folder)
{
    const QString hash = QString::fromLatin1(
        QCryptographicHash::hash(folder.toUtf8(), QCryptographicHash::Sha1).toHex());
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/folders/") + hash + QStringLiteral(".json");
}

QJsonObject readJson(const QString &fileName)
{
    QFile f(fileName);
    if (!f.exists() || !f.open(QIODevice::ReadOnly)) return {};
    return QJsonDocument::fromJson(f.readAll()).object();
}

bool writeJson(const QString &fileName, const QJsonObject &data)
{
    QFile f(fileName);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return false;
    const QByteArray bytes = QJsonDocument(data).toJson(QJsonDocument::Indented);
    return f.write(bytes) == bytes.size();
}

} // namespace

QJsonObject FolderStore::load(const QString &folder)
{
    if (folder.isEmpty()) return {};
    QJsonObject data = readJson(folderFile(folder));
    if (data.isEmpty()) data = readJson(fallbackFile(folder));
    return data;
}

bool FolderStore::save(const QString &folder, const QJsonObject &data)
{
    if (folder.isEmpty()) return false;
    if (isBuiltIn(folder)) {
        // the example class inside the app can't be written to: its data lives with the app
        const QString fallback = fallbackFile(folder);
        QDir().mkpath(QFileInfo(fallback).absolutePath());
        return writeJson(fallback, data);
    }
    if (writeJson(folderFile(folder), data)) {
        QFile::remove(fallbackFile(folder)); // the folder has the current data now
        return true;
    }
    qWarning() << "Couldn't write" << folderFile(folder) << "- using the app's own storage instead";
    const QString fallback = fallbackFile(folder);
    QDir().mkpath(QFileInfo(fallback).absolutePath());
    if (!writeJson(fallback, data))
        qWarning() << "Couldn't write" << fallback << "either";
    return false;
}

void FolderStore::remove(const QString &folder)
{
    if (folder.isEmpty()) return;
    QFile::remove(folderFile(folder));
    QFile::remove(fallbackFile(folder));
}

void FolderStore::takePersistableWritePermission(const QString &folder)
{
#ifdef Q_OS_ANDROID
    if (!folder.startsWith(QLatin1String("content://"))) return;
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    QJniObject resolver = context.callObjectMethod("getContentResolver",
                                                   "()Landroid/content/ContentResolver;");
    QJniObject uri = QJniObject::callStaticObjectMethod(
        "android/net/Uri", "parse", "(Ljava/lang/String;)Landroid/net/Uri;",
        QJniObject::fromString(folder).object<jstring>());
    const jint readWrite = 0x1 | 0x2; // Intent.FLAG_GRANT_READ_URI_PERMISSION | FLAG_GRANT_WRITE_URI_PERMISSION
    resolver.callMethod<void>("takePersistableUriPermission", "(Landroid/net/Uri;I)V",
                              uri.object(), readWrite);
    QJniEnvironment env;
    if (env.checkAndClearExceptions())
        qWarning() << "No permanent write access to" << folder << "- data will be kept in the app";
#else
    Q_UNUSED(folder)
#endif
}
