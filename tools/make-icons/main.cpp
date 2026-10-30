// Generates all app icons from the vector artwork (Stuff(gitignored)/Icon/Icon.svg):
//  - Android adaptive launcher icons (foreground in the safe zone, white background) and
//    legacy icons -> <repo>/android/res/mipmap-*/
//  - 512x512 Play Store icon -> next to the SVG (uploaded by hand)
//  - Windows icon with 16..256 px -> <repo>/windows/FaceZapper.ico
//  - macOS icon with 16..1024 px -> <repo>/mac/FaceZapper.icns
//
// Build with Qt (needs QtSvg) and run:  make-icons <path to Icon.svg> <repo folder>
#include <QBuffer>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <QSvgRenderer>
#include <QtEndian>
#include <cstdio>

static QImage render(QSvgRenderer &svg, int canvas, double artShare, bool whiteBackground)
{
    QImage img(canvas, canvas, QImage::Format_ARGB32_Premultiplied);
    img.fill(whiteBackground ? Qt::white : Qt::transparent);
    QPainter p(&img);
    p.setRenderHint(QPainter::Antialiasing);
    const double art = canvas * artShare, off = (canvas - art) / 2;
    svg.render(&p, QRectF(off, off, art, art));
    return img;
}

// ICO file with PNG-compressed entries (supported since Windows Vista)
static bool writeIco(const QString &fileName, const QList<QImage> &images)
{
    QList<QByteArray> pngs;
    for (const QImage &img : images) {
        QByteArray png;
        QBuffer buf(&png);
        buf.open(QIODevice::WriteOnly);
        img.convertToFormat(QImage::Format_ARGB32).save(&buf, "PNG");
        pngs << png;
    }
    QByteArray ico;
    auto u16 = [&ico](quint16 v) { v = qToLittleEndian(v); ico.append(reinterpret_cast<const char *>(&v), 2); };
    auto u32 = [&ico](quint32 v) { v = qToLittleEndian(v); ico.append(reinterpret_cast<const char *>(&v), 4); };
    u16(0); u16(1); u16(quint16(images.size()));             // header: reserved, type icon, count
    quint32 offset = 6 + 16 * quint32(images.size());
    for (int i = 0; i < images.size(); ++i) {
        const int size = images[i].width();
        ico.append(char(size >= 256 ? 0 : size));             // width (0 = 256)
        ico.append(char(size >= 256 ? 0 : size));             // height
        ico.append(char(0)); ico.append(char(0));             // colours, reserved
        u16(1); u16(32);                                      // planes, bits per pixel
        u32(quint32(pngs[i].size())); u32(offset);
        offset += quint32(pngs[i].size());
    }
    for (const QByteArray &png : pngs) ico.append(png);
    QFile f(fileName);
    return f.open(QIODevice::WriteOnly) && f.write(ico) == ico.size();
}

// ICNS file with PNG entries (Mac OS X 10.7+): every size macOS asks for, plain and Retina (@2x)
static bool writeIcns(const QString &fileName, QSvgRenderer &svg)
{
    const QList<QPair<QByteArray, int>> entries = {
        {"icp4", 16}, {"icp5", 32}, {"ic07", 128}, {"ic08", 256}, {"ic09", 512},  // 1x
        {"ic11", 32}, {"ic12", 64}, {"ic13", 256}, {"ic14", 512}, {"ic10", 1024}, // @2x of 16..512
    };
    QByteArray body;
    for (const auto &e : entries) {
        QByteArray png;
        QBuffer buf(&png);
        buf.open(QIODevice::WriteOnly);
        render(svg, e.second, 1.0, false).convertToFormat(QImage::Format_ARGB32).save(&buf, "PNG");
        const quint32 len = qToBigEndian(quint32(8 + png.size()));
        body += e.first + QByteArray(reinterpret_cast<const char *>(&len), 4) + png;
    }
    const quint32 total = qToBigEndian(quint32(8 + body.size()));
    const QByteArray icns = "icns" + QByteArray(reinterpret_cast<const char *>(&total), 4) + body;
    QFile f(fileName);
    return f.open(QIODevice::WriteOnly) && f.write(icns) == icns.size();
}

int main(int argc, char **argv)
{
    QGuiApplication a(argc, argv);
    if (argc < 3) {
        printf("usage: make-icons <Icon.svg> <repo folder>\n");
        return 1;
    }
    const QString svgFile = QString::fromLocal8Bit(argv[1]);
    const QString repo = QString::fromLocal8Bit(argv[2]);
    QSvgRenderer svg(svgFile);
    if (!svg.isValid()) {
        printf("cannot read %s\n", argv[1]);
        return 1;
    }

    // Android: adaptive icon on a 108dp canvas, artwork kept inside the 66dp safe circle
    const QList<QPair<QString, int>> densities = {{"mdpi", 108}, {"hdpi", 162}, {"xhdpi", 216}, {"xxhdpi", 324}, {"xxxhdpi", 432}};
    for (const auto &d : densities) {
        const QString dir = repo + "/android/res/mipmap-" + d.first;
        QDir().mkpath(dir);
        render(svg, d.second, 0.58, false).save(dir + "/ic_launcher_foreground.png");
        render(svg, d.second * 48 / 108, 0.80, true).save(dir + "/ic_launcher.png"); // legacy 48dp
    }
    // Play Store listing icon: square, no transparency
    render(svg, 512, 0.80, true).convertToFormat(QImage::Format_RGB32)
        .save(QFileInfo(svgFile).absolutePath() + "/playstore-icon-512.png");

    // Windows: transparent background, artwork filling the square
    QList<QImage> sizes;
    for (int s : {16, 24, 32, 48, 64, 128, 256})
        sizes << render(svg, s, 1.0, false);
    QDir().mkpath(repo + "/windows");
    if (!writeIco(repo + "/windows/FaceZapper.ico", sizes)) {
        printf("cannot write the .ico\n");
        return 1;
    }

    // macOS: transparent like Windows, 16..1024 px
    QDir().mkpath(repo + "/mac");
    if (!writeIcns(repo + "/mac/FaceZapper.icns", svg)) {
        printf("cannot write the .icns\n");
        return 1;
    }
    printf("icons written\n");
    return 0;
}
