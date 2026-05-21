#include "memory_view.h"
#include "temu_wrapper.h"
#include <QHeaderView>
#include <QMessageBox>

MemoryView::MemoryView(QWidget *parent)
    : QWidget(parent), m_startAddr(0x80000000), m_endAddr(0x8000FFFF), m_updating(false)
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    
    m_titleLabel = new QLabel("Memory View", this);
    m_titleLabel->setStyleSheet("font-weight: bold; font-size: 12pt;");
    mainLayout->addWidget(m_titleLabel);
    
    // Controls
    QHBoxLayout *controlLayout = new QHBoxLayout();
    controlLayout->addWidget(new QLabel("Segment:", this));
    
    m_segmentCombo = new QComboBox(this);
    m_segmentCombo->addItem("Code (.text)");
    m_segmentCombo->addItem("Data (.data)");
    controlLayout->addWidget(m_segmentCombo);
    
    controlLayout->addWidget(new QLabel("Jump to:", this));
    m_addressEdit = new QLineEdit(this);
    m_addressEdit->setPlaceholderText("0x80000000");
    controlLayout->addWidget(m_addressEdit);
    
    m_jumpButton = new QPushButton("Jump", this);
    controlLayout->addWidget(m_jumpButton);
    controlLayout->addStretch();
    
    mainLayout->addLayout(controlLayout);
    
    // Memory table
    setupTable();
    mainLayout->addWidget(m_table);
    
    setLayout(mainLayout);
    
    // Connect signals
    connect(m_segmentCombo, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &MemoryView::onSegmentChanged);
    connect(m_jumpButton, &QPushButton::clicked, this, &MemoryView::onJumpClicked);
    connect(m_table, &QTableWidget::itemChanged, this, &MemoryView::onTableItemChanged);
    
    // Initial fill
    fillMemoryTable(m_startAddr, m_endAddr);
}

void MemoryView::setupTable()
{
    m_table = new QTableWidget(256, 9, this); // 256 rows, 1 addr + 8 bytes
    QStringList headers;
    headers << "Address";
    for (int i = 0; i < 8; i++) {
        headers << QString("+%1").arg(i);
    }
    m_table->setHorizontalHeaderLabels(headers);
    m_table->verticalHeader()->setVisible(false);
    m_table->setEditTriggers(QAbstractItemView::DoubleClicked);
    m_table->setAlternatingRowColors(true);
    m_table->setFont(QFont("Courier", 9));
    
    // Set column widths
    m_table->setColumnWidth(0, 100);
    for (int i = 1; i < 9; i++) {
        m_table->setColumnWidth(i, 60);
    }
}

void MemoryView::fillMemoryTable(uint32_t startAddr, uint32_t endAddr)
{
    m_updating = true;
    m_table->setRowCount(0);
    
    int row = 0;
    for (uint32_t addr = startAddr; addr <= endAddr && row < 256; addr += 8) {
        m_table->insertRow(row);
        
        // Address column
        QTableWidgetItem *addrItem = new QTableWidgetItem(
            QString("0x%1").arg(addr, 8, 16, QChar('0')).toUpper());
        addrItem->setFlags(addrItem->flags() & ~Qt::ItemIsEditable);
        m_table->setItem(row, 0, addrItem);
        
        // Data columns
        for (int i = 0; i < 8; i++) {
            updateMemoryCell(row, i + 1, addr + i);
        }
        
        row++;
    }
    
    m_updating = false;
}

void MemoryView::updateMemoryCell(int row, int col, uint32_t addr)
{
    uint32_t value = temu_get_memory(addr, 1);
    QTableWidgetItem *item = new QTableWidgetItem(
        QString("%1").arg(value, 2, 16, QChar('0')).toUpper());
    m_table->setItem(row, col, item);
}

void MemoryView::updateMemory()
{
    if (m_updating) return;
    
    m_updating = true;
    
    for (int row = 0; row < m_table->rowCount(); row++) {
        QTableWidgetItem *addrItem = m_table->item(row, 0);
        if (!addrItem) continue;
        
        bool ok;
        uint32_t baseAddr = addrItem->text().toULong(&ok, 16);
        if (!ok) continue;
        
        for (int col = 1; col < 9; col++) {
            updateMemoryCell(row, col, baseAddr + col - 1);
        }
    }
    
    m_updating = false;
}

void MemoryView::setAddressRange(uint32_t start, uint32_t end)
{
    m_startAddr = start;
    m_endAddr = end;
    fillMemoryTable(start, end);
}

void MemoryView::jumpToAddress(uint32_t addr)
{
    // Find the row containing this address
    for (int row = 0; row < m_table->rowCount(); row++) {
        QTableWidgetItem *addrItem = m_table->item(row, 0);
        if (!addrItem) continue;
        
        bool ok;
        uint32_t baseAddr = addrItem->text().toULong(&ok, 16);
        if (!ok) continue;
        
        if (addr >= baseAddr && addr < baseAddr + 8) {
            m_table->scrollToItem(addrItem);
            m_table->selectRow(row);
            break;
        }
    }
}

void MemoryView::onSegmentChanged(int index)
{
    if (index == 0) {
        // Code segment
        setAddressRange(0x80000000, 0x8000FFFF);
    } else {
        // Data segment
        setAddressRange(0x80010000, 0x8001FFFF);
    }
}

void MemoryView::onJumpClicked()
{
    QString addrText = m_addressEdit->text();
    bool ok;
    uint32_t addr = addrText.toULong(&ok, 16);
    
    if (!ok) {
        QMessageBox::warning(this, "Invalid Address", 
                           "Please enter a valid hexadecimal address (e.g., 0x80000000)");
        return;
    }
    
    jumpToAddress(addr);
}

void MemoryView::onTableItemChanged(QTableWidgetItem *item)
{
    if (m_updating || item->column() == 0) return;
    
    // Get the address from the row
    QTableWidgetItem *addrItem = m_table->item(item->row(), 0);
    if (!addrItem) return;
    
    bool ok;
    uint32_t baseAddr = addrItem->text().toULong(&ok, 16);
    if (!ok) return;
    
    uint32_t addr = baseAddr + item->column() - 1;
    uint32_t value = item->text().toULong(&ok, 16);
    
    if (ok) {
        temu_write_memory(addr, 1, value);
    }
}

