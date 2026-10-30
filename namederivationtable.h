#ifndef NAMEDERIVATIONTABLE_H
#define NAMEDERIVATIONTABLE_H

#include <QAbstractTableModel>
#include <QObject>
#include <QRandomGenerator>
#include <QString>
#include <QJsonArray>
#include <persondata.h>

class NameDerivationTable : public QAbstractTableModel {
    Q_OBJECT
    enum TableRoles { TableDataRole = Qt::UserRole + 1, HeadingRole, OverrideAutomaticRole, ExcludeRole};
public:
    enum class DelimiterCounterOption {
        FIRST_FROM_LEFT = 0,
        FIRST_FROM_RIGHT = 1,
        SECOND_FROM_LEFT = 2,
        SECOND_FROM_RIGHT = 3,
        MIDDLE_LEFT = 4,
        MIDDLE_RIGHT = 5
    };
    Q_ENUM(DelimiterCounterOption)

    enum class DeletionLocationOption {
        LEFT = 0,
        RIGHT = 1,
        SIDES = 2,
        NOT = 3,
        ALL = 4
    };
    Q_ENUM(DeletionLocationOption)

    explicit NameDerivationTable(QObject *parent = nullptr);
    void init(QString fileName);
    void clear();
    int rowCount(const QModelIndex & = QModelIndex()) const override { return m_table.size(); }
    // view column 0 is the mode button column, view column n shows m_table column n-1
    int columnCount(const QModelIndex & = QModelIndex()) const override { return m_table.at(0).size() + 1; }

    void clicked(int row, int column,
                 DeletionLocationOption deleteNumberLocationOption,
                 int deleteNumberCount,
                 DeletionLocationOption deleteCharsLocationOption,
                 QString deleteCharsText,
                 QString replaceFrom,
                 QString replaceTo,
                 Qt::CaseSensitivity caseSensitivity,
                 QString delimiter,
                 DelimiterCounterOption delimiterCounterOption,
                 bool correctCase,
                 bool firstNameFirst);

    Q_INVOKABLE void dataEdited(int row, int column, QString text);
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addRow(QString fileName, QString baseName);

    QList<int> delimiterPlaces(QString s, QString delimiter);
    void separateStringToNames(QString stripped, QString *firstName, QString *familyName, QString delimiter, QList<int> occasions, DelimiterCounterOption option, bool correctCase, bool firstNameFirst);
    QString deleteNumberOfChars(QString s, DeletionLocationOption deleteNumberLocationOption, int deleteNumberCount);
    QString deleteSpecialChars(QString s, DeletionLocationOption deleteCharsLocationOption, QString deleteCharsText);
    QString replaceFromChunk(QString s, QString from, Qt::CaseSensitivity caseSensitivity);
    QString replace(QString s, QString from, QString to, Qt::CaseSensitivity caseSensitivity);

    void deriveOneName(int i,
                       DeletionLocationOption deleteNumberLocationOption,
                       int deleteNumberCount,
                       DeletionLocationOption deleteCharsLocationOption,
                       QString deleteCharsText,
                       QString replaceFrom,
                       QString replaceTo,
                       Qt::CaseSensitivity caseSensitivity,
                       QString delimiter,
                       DelimiterCounterOption delimiterCounterOption,
                       bool correctCase,
                       bool firstNameFirst);

    void runNameDerivation(DeletionLocationOption deleteNumberLocationOption,
                           int deleteNumberCount,
                           DeletionLocationOption deleteCharsLocationOption,
                           QString deleteCharsText,
                           QString replaceFrom,
                           QString replaceTo,
                           Qt::CaseSensitivity caseSensitivity,
                           QString delimiter,
                           DelimiterCounterOption delimiterCounterOption,
                           bool correctCase,
                           bool firstNameFirst);

    void fillPersonDataMap(QVector<PersonData*> *personsVector) {
        int uid = 0;
        Q_ASSERT(personsVector->isEmpty()); // may be subject to change if we allow the adding of a folder to existing pics
        for (int i = 1; i < m_table.count(); i++) { // row 0 is the heading
            if (m_exclude.at(i)) continue;
            auto p = new PersonData();
            p->setPicFileName(m_table.at(i).at(2));
            p->setFirstName(m_table.at(i).at(0));
            p->setFamilyName(m_table.at(i).at(1));
            p->setUid(uid++);
            personsVector->append(p);
        }
    };
    QString groupName() const;
    void setGroupName(const QString &newGroupName);

    // per file: mode ("auto", "manual", "excluded") and, for manual rows, the names typed in
    QJsonArray rowsToJson() const;
    void applyRows(const QJsonArray &rows); // rows are matched by file name, unknown files are ignored

private:
    QVector<QVector<QString>> m_table;
    QVector<QString> m_baseName;
    QVector<bool> m_overrideAutomatic;
    QVector<bool> m_exclude;
    QString m_groupName = "";
};

#endif // NAMEDERIVATIONTABLE_H
