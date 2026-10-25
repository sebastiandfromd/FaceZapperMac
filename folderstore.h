#ifndef FOLDERSTORE_H
#define FOLDERSTORE_H

#include <QJsonObject>
#include <QString>

// Reads and writes ".faceZapperData" (JSON) inside a picture folder, so the data
// travels with the folder. If the folder can't be written to, the data goes to
// AppDataLocation instead (file name: hash of the folder path).
// Works with local paths and Android content:// tree URIs.
namespace FolderStore
{
    inline constexpr char dataFileName[] = ".faceZapperData";

    // empty object if there is no data yet
    QJsonObject load(const QString &folder);
    // returns false if only the fallback location could be written
    bool save(const QString &folder, const QJsonObject &data);
    // deletes the data in the folder and in the fallback location
    void remove(const QString &folder);

    // Android: Qt's folder picker keeps only read access across restarts - ask for write access, too
    void takePersistableWritePermission(const QString &folder);
}

#endif // FOLDERSTORE_H
