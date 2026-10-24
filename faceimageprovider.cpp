#include "faceimageprovider.h"


QImage FaceImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(requestedSize)
    QImage i(id);
    if (size)
        *size = QSize(i.width(), i.height());
    return i;
}
