#include "lettermodel.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QCollator>
#include <QRegularExpression>
#include <algorithm>

// folder names are few but exactly the ones being learned, so they count more
static constexpr double folderWeight = 5.0;
static const QString alphabet = QStringLiteral("ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ");

bool LetterModel::load(const QString &fileName)
{
    QFile f(fileName);
    if (!f.open(QIODevice::ReadOnly)) return false;
    const QJsonObject root = QJsonDocument::fromJson(f.readAll()).object();
    m_start.clear();
    m_next.clear();
    const QJsonObject start = root.value("start").toObject();
    for (auto it = start.begin(); it != start.end(); ++it)
        m_start[it.key().at(0)] = it.value().toDouble();
    const QJsonObject next = root.value("next").toObject();
    for (auto it = next.begin(); it != next.end(); ++it) {
        const QJsonObject o = it.value().toObject();
        Counts &c = m_next[it.key()];
        for (auto jt = o.begin(); jt != o.end(); ++jt)
            c[jt.key().at(0)] = jt.value().toDouble();
    }
    return !m_start.isEmpty();
}

void LetterModel::setFolderNames(const QStringList &names)
{
    m_folderStart.clear();
    m_folderNext.clear();
    for (const QString &name : names)
        for (const QString &word : normalize(name).split(' ', Qt::SkipEmptyParts))
            addWord(word, folderWeight, m_folderStart, m_folderNext);
}

void LetterModel::addWord(const QString &word, double weight, Counts &start, QHash<QString, Counts> &next)
{
    QString w;
    for (QChar c : word)
        if (c.isLetter()) w += c; // same as the statistics: letters only
    if (w.isEmpty()) return;
    start[w.at(0)] += weight;
    const QString s = w + u' ';
    for (int i = 1; i < s.size(); ++i)
        for (int k = 1; k <= 3 && k <= i; ++k)
            next[s.mid(i - k, k)][s.at(i)] += weight;
}

QString LetterModel::normalize(const QString &s)
{
    QString out;
    for (QChar c : s)
        out += (c == u'ß') ? c : c.toUpper();
    return out; // no trimming: a trailing space in the typed text matters
}

LetterModel::Counts LetterModel::candidates(const QString &typed) const
{
    // the current name part decides: after a space or hyphen (or at the very beginning) a new part starts
    const QString t = normalize(typed);
    const QString word = t.section(QRegularExpression(QStringLiteral("[ -]")), -1);
    QString letters;
    for (QChar c : word)
        if (c.isLetter()) letters += c;

    Counts result;
    auto add = [&result](const Counts &c, double factor) {
        for (auto it = c.cbegin(); it != c.cend(); ++it) result[it.key()] += it.value() * factor;
    };
    if (letters.isEmpty()) {
        add(m_start, 1);
        add(m_folderStart, 1);
        return result;
    }
    // longest known context counts most, shorter ones back it up (back-off)
    double factor = 1.0;
    for (int k = qMin(3, int(letters.size())); k >= 1; --k) {
        const QString ctx = letters.right(k);
        add(m_next.value(ctx), factor);
        add(m_folderNext.value(ctx), factor);
        factor *= 0.1;
    }
    return result;
}

QStringList LetterModel::keys(const QString &target, const QString &typed, int count) const
{
    const QString t = normalize(target);
    const QString ty = normalize(typed);
    QChar correct;
    if (t.startsWith(ty) && ty.size() < t.size())
        correct = t.at(ty.size());

    QString chosen;
    if (!correct.isNull()) chosen += correct;

    // decoys: weighted random draw without repeats
    const bool newPart = typed.isEmpty() || typed.endsWith(u' ') || typed.endsWith(u'-');
    Counts c = candidates(typed);
    c.remove(correct);
    if (newPart) c.remove(u' '); // no leading or double space, no space after a hyphen
    while (chosen.size() < count && !c.isEmpty()) {
        double total = 0;
        for (double w : c) total += w;
        double r = QRandomGenerator::global()->generateDouble() * total;
        auto it = c.begin();
        for (; it != c.end(); ++it) {
            r -= it.value();
            if (r <= 0) break;
        }
        if (it == c.end()) it = std::prev(c.end());
        chosen += it.key();
        c.erase(it);
    }
    // not enough known continuations: fill up with random letters
    while (chosen.size() < count) {
        const QChar l = alphabet.at(int(QRandomGenerator::global()->bounded(alphabet.size())));
        if (!chosen.contains(l)) chosen += l;
    }

    // sorted: space first, then letters in German order (Ä next to A)
    QStringList result;
    for (QChar ch : chosen)
        result << (newPart || ch == u'ß' ? QString(ch) : QString(ch).toLower());
    QCollator collator{QLocale(QLocale::German)};
    std::sort(result.begin(), result.end(), [&collator](const QString &a, const QString &b) {
        if (a == u" ") return b != u" ";
        if (b == u" ") return false;
        return collator.compare(a, b) < 0;
    });
    return result;
}
