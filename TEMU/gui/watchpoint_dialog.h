#ifndef WATCHPOINT_DIALOG_H
#define WATCHPOINT_DIALOG_H

#include <QDialog>
#include <QTableWidget>
#include <QLineEdit>
#include <QPushButton>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>

class WatchpointDialog : public QDialog
{
    Q_OBJECT

public:
    explicit WatchpointDialog(QWidget *parent = nullptr);
    void updateWatchpoints();

signals:
    // Notify main window (or others) that watchpoints changed
    void watchpointsChanged();

private slots:
    void onAddClicked();
    void onDeleteClicked();
    void onRefreshClicked();

private:
    QTableWidget *m_table;
    QLineEdit *m_exprEdit;
    QPushButton *m_addButton;
    QPushButton *m_deleteButton;
    QPushButton *m_refreshButton;
};

#endif // WATCHPOINT_DIALOG_H
