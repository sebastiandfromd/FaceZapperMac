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
    // Contains the next correct character of `target` exactly once if `typed` is a correct
    // prefix and the name isn't complete yet - otherwise only decoys (after a mistake,
    // backspace is the correct key).
    QStringList keys(const QString &target, const QString &typed, int count = 8) const;

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
