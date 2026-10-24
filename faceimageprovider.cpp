#include "faceimageprovider.h"
#include <QUrl>
#include <QImageReader>

static constexpr int maxEdge = 1600;

QImage FaceImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    const QString fileName = QUrl::fromPercentEncoding(id.toUtf8());
    // Android content URIs: a child of a tree URI is addressed as "<tree uri>/<encoded name>",
    // Qt's content file engine resolves that to the document
    const QString path = m_folder.contains(QStringLiteral("://"))
                             ? m_folder + u'/' + QString::fromUtf8(QUrl::toPercentEncoding(fileName))
                             : m_folder + u'/' + fileName;
    // decode at reduced size: camera photos (~3000x4000) would need ~50 MB each, too much on phones
    QImageReader reader(path);
    reader.setAutoTransform(true); // respect EXIF orientation of phone photos
    QSize target = requestedSize.isValid() ? requestedSize : QSize(maxEdge, maxEdge);
    const QSize original = reader.size();
    if (original.isValid() && (original.width() > target.width() || original.height() > target.height()))
        reader.setScaledSize(original.scaled(target, Qt::KeepAspectRatio));
    QImage i = reader.read();
    if (i.isNull())
        qWarning() << "FaceImageProvider: could not load" << path;
    if (size)
        *size = QSize(i.width(), i.height());
    return i;
}
