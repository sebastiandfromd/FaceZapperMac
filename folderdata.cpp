#include "folderdata.h"

FolderData::FolderData()
{

}

QString FolderData::path() const
{
    return m_path;
}

void FolderData::setPath(const QString &newPath)
{
    m_path = newPath;
}

QString FolderData::name() const
{
    return m_name;
}

void FolderData::setName(const QString &newName)
{
    m_name = newName;
}
