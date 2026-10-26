#ifndef LETTERMODEL_H
#define LETTERMODEL_H

#include <QHash>
#include <QString>
#include <QStringList>

// Which letters are likely to come next in a name. Based on aggregated letter counts
// (letterstats.json: start letters and context of 1-3 letters -> next letter, where
// ' ' means "name part ends here") plus the names of the current folder (in memory only).
class LetterModel
{
public:
    bool load(const QString &fileName);
    void setFolderNames(const QStringList &names); // replaces the previous folder's names

    // Keys for the letter keyboard: `count` different characters, sorted (space first).
    // Hyphens and apostrophes are normal characters: they appear when they're the next correct one.
    // `targets` are the accepted spellings (e.g. "Anna Lena Groß" and "Anna Groß"): every next
    // character of a target that `typed` is a prefix of is on the keyboard exactly once - usually
    // that's one key, at a point where a middle name may be left out it can be two. If `typed`
    // fits no target (a mistake, backspace is the correct key) or is complete, there are only decoys.
    QStringList keys(const QStringList &targets, const QString &typed, int count = 8) const;
    QStringList keys(const QString &target, const QString &typed, int count = 8) const
    { return keys(QStringList{target}, typed, count); }

    static QString normalize(const QString &s); // upper case per character, ß stays ß, no trimming

private:
    using Counts = QHash<QChar, double>;
    Counts candidates(const QString &typed) const;
    static void addWord(const QString &word, double weight, Counts &start, QHash<QString, Counts> &next);

    Counts m_start;
    QHash<QString, Counts> m_next;
    Counts m_folderStart;
    QHash<QString, Counts> m_folderNext;
};

#endif // LETTERMODEL_H
