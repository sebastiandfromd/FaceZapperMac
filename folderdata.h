#ifndef FOLDERDATA_H
#define FOLDERDATA_H
#include <QString>

class FolderData
{
public:
    FolderData();

    Q_INVOKABLE QString path() const;
    void setPath(const QString &newPath);

    QString name() const;
    void setName(const QString &newName);

private:
    QString m_path;
    QString m_name;

};

#endif // FOLDERDATA_H
