// Play Store assets: screenshots cropped/padded to 2:1 and the 1024x500 feature graphic per store language.
//   make-store-assets <shots dir> <out dir> <Icon.svg> <example folder>
// <shots dir>: raw phone screenshots (adb exec-out screencap -p), named as in the list below;
//              "-" makes only the feature graphics.
// <example folder>: the example group's photos (for the row of faces).
// Example:
//   make-store-assets - "Stuff(gitignored)/PlayStore" "Stuff(gitignored)/Icon/Icon.svg" "Klasse 10d (Beispiel)"
#include <QDir>
#include <QFont>
#include <QFontMetrics>
#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <QPainterPath>
#include <QSvgRenderer>
#include <cstdio>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    const QString shots = argv[1], out = argv[2], svgFile = argv[3], faces = argv[4];
    QDir().mkpath(out);

    // screenshots: drop the status bar and the white cutout strip on the left, then pad to 2:1
    // by repeating the top and bottom pixel rows (background and footer just get taller)
    const QList<QPair<QString, QString>> list = {
        {"raw-1-lernen", "1-lernen"}, {"raw-2-tippen", "2-tippen"}, {"raw-gruen", "3-richtig"},
        {"raw-gelb", "4-fast"}, {"raw-loesung", "5-loesung"}, {"raw-tabelle", "6-namen"},
        {"raw-settings", "7-einstellungen"}, {"raw-info", "8-erklaerung"}};
    for (const auto &e : list) {
        if (shots == "-") break;   // "-": feature graphics only
        QImage raw(shots + "/" + e.first + ".png");
        if (raw.isNull()) { fprintf(stderr, "missing %s\n", qPrintable(e.first)); continue; }
        raw = raw.convertToFormat(QImage::Format_RGB32);
        // the camera cutout leaves a plain strip on the left (white up to 1.2, the window background
        // since 1.3): continue the app's first column into it (rows where the strip isn't plain,
        // like the footer, already belong to the app)
        const int strip = 131;
        for (int y = 0; y < raw.height(); ++y) {
            bool plain = true;
            for (int x = 1; x < strip && plain; ++x) plain = raw.pixel(x, y) == raw.pixel(0, y);
            if (!plain) continue;
            const QRgb fill = raw.pixel(strip, y);
            for (int x = 0; x < strip; ++x) raw.setPixel(x, y, fill);
        }
        const QImage c = raw.copy(0, 74, raw.width(), raw.height() - 74);
        const int w = c.width(), h = (w + 1) / 2, pad = h - c.height(), top = pad / 2;
        QImage img(w, h, QImage::Format_RGB32);
        QPainter p(&img);
        for (int y = 0; y < top; ++y) p.drawImage(0, y, c, 0, 0, w, 1);
        p.drawImage(0, top, c);
        for (int y = top + c.height(); y < h; ++y) p.drawImage(0, y, c, 0, c.height() - 1, w, 1);
        p.end();
        img.save(out + "/" + e.second + ".png");
        printf("%s %dx%d\n", qPrintable(e.second), w, h);
    }

    // feature graphic 1024x500 per store language: icon left, name and slogan, a row of example faces
    const QList<QPair<QString, QString>> slogans = {
        {"", "Namen und Gesichter lernen"}, {"-en", "Learn names and faces"},
        {"-es", "Aprender nombres y caras"}, {"-fr", "Apprendre les noms et les visages"},
        {"-it", "Imparare nomi e volti"}, {"-nl", "Namen en gezichten leren"},
        {"-pt-BR", "Aprender nomes e rostos"}};
    for (const auto &sl : slogans) {
    QImage fg(1024, 500, QImage::Format_RGB32);
    fg.fill(Qt::white);
    QPainter p(&fg);
    p.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform | QPainter::TextAntialiasing);
    QSvgRenderer svg(svgFile);
    svg.render(&p, QRectF(50, 85, 330, 330));
    QFont title("Segoe UI", 1, QFont::Bold);
    title.setPixelSize(84);
    p.setFont(title);
    p.setPen(QColor(0x22, 0x22, 0x22));
    p.drawText(QRectF(410, 95, 590, 110), Qt::AlignLeft | Qt::AlignVCenter, "FaceZapper");
    QFont sub("Segoe UI");
    sub.setPixelSize(38);
    while (QFontMetrics(sub).horizontalAdvance(sl.second) > 585) sub.setPixelSize(sub.pixelSize() - 1);
    p.setFont(sub);
    p.setPen(QColor(0x00, 0x80, 0x80));
    p.drawText(QRectF(414, 200, 590, 60), Qt::AlignLeft | Qt::AlignVCenter, sl.second);
    const QStringList names = {"Schwarz, Maya", "Osei-Tutu, Kofi", "Nguyen, Linh-Dan", "Becker, Elias", "McCarthy, Maeve"};
    const int d = 96, gap = 18;
    for (int i = 0; i < names.size(); ++i) {
        QImage face(faces + "/" + names[i] + ".jpeg");
        if (face.isNull()) { fprintf(stderr, "missing face %s\n", qPrintable(names[i])); continue; }
        // square from the upper part of the portrait (where the face is)
        const int s = face.width();
        const QImage sq = face.copy(0, qMax(0, (face.height() - s) / 3), s, s)
                              .scaled(d * 2, d * 2, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
        const QRectF r(414 + i * (d + gap), 300, d, d);
        QPainterPath clip;
        clip.addEllipse(r);
        p.save();
        p.setClipPath(clip);
        p.drawImage(r, sq);
        p.restore();
        p.setPen(QPen(i % 2 ? QColor(0xe2, 0x00, 0x1a) : QColor(0x00, 0x8f, 0x39), 5));
        p.setBrush(Qt::NoBrush);
        p.drawEllipse(r.adjusted(2.5, 2.5, -2.5, -2.5));
    }
    p.end();
    fg.save(out + "/feature-graphic" + sl.first + "-1024x500.png");
    printf("feature graphic%s: slogan %dpx\n", qPrintable(sl.first), sub.pixelSize());
    }
    return 0;
}
