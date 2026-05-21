#include "watchpoint_dialog.h"
#include "temu_wrapper.h"
#include <QHeaderView>
#include <QMessageBox>

WatchpointDialog::WatchpointDialog(QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle("Watchpoints");
    setMinimumSize(500, 400);

    QVBoxLayout *mainLayout = new QVBoxLayout(this);

    // Table
    m_table = new QTableWidget(0, 3, this);
    m_table->setHorizontalHeaderLabels(QStringList() << "No" << "Expression" << "Value");
    m_table->setSelectionBehavior(QAbstractItemView::SelectRows);
    m_table->setAlternatingRowColors(true);
    m_table->setEditTriggers(QAbstractItemView::NoEditTriggers);

    m_table->horizontalHeader()->setStretchLastSection(true);
    m_table->setColumnWidth(0, 60);
    m_table->setColumnWidth(1, 300);

    mainLayout->addWidget(m_table);

    // Input area
    QHBoxLayout *inputLayout = new QHBoxLayout();
    inputLayout->addWidget(new QLabel("Expression:", this));
    m_exprEdit = new QLineEdit(this);
    m_exprEdit->setPlaceholderText("e.g., $r4 == 0x1010");
    inputLayout->addWidget(m_exprEdit);

    m_addButton = new QPushButton("Add", this);
    inputLayout->addWidget(m_addButton);

    mainLayout->addLayout(inputLayout);

    // Buttons
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    m_deleteButton = new QPushButton("Delete", this);
    m_refreshButton = new QPushButton("Refresh", this);
    QPushButton *closeButton = new QPushButton("Close", this);

    buttonLayout->addWidget(m_deleteButton);
    buttonLayout->addWidget(m_refreshButton);
    buttonLayout->addStretch();
    buttonLayout->addWidget(closeButton);

    mainLayout->addLayout(buttonLayout);

    setLayout(mainLayout);

    // Connect signals
    connect(m_addButton, &QPushButton::clicked, this, &WatchpointDialog::onAddClicked);
    connect(m_deleteButton, &QPushButton::clicked, this, &WatchpointDialog::onDeleteClicked);
    connect(m_refreshButton, &QPushButton::clicked, this, &WatchpointDialog::onRefreshClicked);
    connect(closeButton, &QPushButton::clicked, this, &QDialog::accept);

    // Initial update
    updateWatchpoints();
}

void WatchpointDialog::updateWatchpoints()
{
    m_table->setRowCount(0);

    WatchpointInfo list[32];
    int n = temu_list_watchpoints(list, 32);

    m_table->setRowCount(n);
    for (int i = 0; i < n; i++) {
        m_table->setItem(i, 0, new QTableWidgetItem(QString::number(list[i].no)));
        m_table->setItem(i, 1, new QTableWidgetItem(QString::fromLocal8Bit(list[i].expr)));
        m_table->setItem(i, 2, new QTableWidgetItem(QString("0x%1").arg(list[i].value, 8, 16, QChar('0'))));
    }

    emit watchpointsChanged();
}

void WatchpointDialog::onAddClicked()
{
    QString expr = m_exprEdit->text().trimmed();
    if (expr.isEmpty()) {
        QMessageBox::warning(this, "Empty Expression", "Please enter an expression.");
        return;
    }

    int wpNo = temu_set_watchpoint(expr.toLocal8Bit().constData());
    if (wpNo >= 0) {
        m_exprEdit->clear();
        updateWatchpoints();
        QMessageBox::information(this, "Success",
                                 QString("Watchpoint %1 added successfully.").arg(wpNo));
    } else {
        QMessageBox::warning(this, "Error", "Failed to add watchpoint. Check expression syntax.");
    }
}

void WatchpointDialog::onDeleteClicked()
{
    int row = m_table->currentRow();
    if (row < 0) {
        QMessageBox::warning(this, "No Selection", "Please select a watchpoint to delete.");
        return;
    }

    QTableWidgetItem *noItem = m_table->item(row, 0);
    if (!noItem) return;

    bool ok;
    int wpNo = noItem->text().toInt(&ok);
    if (ok) {
        temu_delete_watchpoint(wpNo);
        updateWatchpoints();
    }
}

void WatchpointDialog::onRefreshClicked()
{
    updateWatchpoints();
}
