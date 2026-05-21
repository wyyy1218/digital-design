#include "code_view.h"
#include "temu_wrapper.h"
#include <QFile>
#include <QTextStream>
#include <QScrollBar>
#include <QTextBlock>
#include <QTextCursor>
#include <QMessageBox>
#include <QSignalBlocker>

CodeView::CodeView(QWidget *parent)
    : QWidget(parent), m_currentPC(0)
{
    QVBoxLayout *layout = new QVBoxLayout(this);
    
    m_titleLabel = new QLabel("Code View", this);
    m_titleLabel->setStyleSheet("font-weight: bold; font-size: 12pt;");
    layout->addWidget(m_titleLabel);
    
    m_textEdit = new QTextEdit(this);
    m_textEdit->setReadOnly(true);
    m_textEdit->setFont(QFont("Courier", 10));
    m_textEdit->setLineWrapMode(QTextEdit::NoWrap);
    
    layout->addWidget(m_textEdit);
    setLayout(layout);
    
    // NOTE: Do NOT connect textChanged -> updateDisplay.
    // updateDisplay() calls m_textEdit->setHtml(), which emits textChanged again,
    // causing infinite recursion / stack overflow / Qt heap corruption (often shows
    // as a crash inside QString::reallocData).
}

void CodeView::loadInstructions()
{
    m_instructions.clear();
    
    // Load instructions from inst.bin
    QFile file("inst.bin");
    if (!file.open(QIODevice::ReadOnly)) {
        m_textEdit->setPlainText("Error: Could not open inst.bin");
        return;
    }
    
    QDataStream stream(&file);
    stream.setByteOrder(QDataStream::LittleEndian);
    
    uint32_t address = 0x80000000;
    while (!stream.atEnd()) {
        uint32_t instruction;
        if (stream.readRawData(reinterpret_cast<char*>(&instruction), 4) != 4) {
            break;
        }
        
        Instruction instr;
        instr.address = address;
        instr.machineCode = instruction;
        instr.assembly = disassembleInstruction(address, instruction);
        instr.isBreakpoint = hasBreakpoint(address);
        
        m_instructions.push_back(instr);
        address += 4;
    }
    
    file.close();
    updateDisplay();
}

QString CodeView::disassembleInstruction(uint32_t /*pc*/, uint32_t code)
{
    // For now, we'll use a simple format showing the machine code
    // A full disassembler would decode the instruction format
    // This is a placeholder - in a real implementation, you would
    // decode the instruction based on opcode and format
    return QString("[0x%1]")
        .arg(code, 8, 16, QChar('0'));
}

void CodeView::updateDisplay()
{
    // Use <pre> to preserve newlines/spaces. Otherwise QTextEdit's rich-text
    // renderer may collapse "\n" into whitespace and display all instructions
    // on a single long line.
    QString text;
    QTextStream stream(&text);

    stream << "<pre style='margin:0; font-family:Courier; font-size:10pt;'>";

    for (const auto &instr : m_instructions) {
        QString line = QString("0x%1: 0x%2    %3")
            .arg(instr.address, 8, 16, QChar('0'))
            .arg(instr.machineCode, 8, 16, QChar('0'))
            .arg(instr.assembly.isEmpty() ? "[instruction]" : instr.assembly);

        if (instr.isBreakpoint) {
            line = QString("● %1").arg(line);
        }

        if (instr.address == m_currentPC) {
            // Highlight current PC line
            line = QString("<span style='background-color: yellow;'>%1</span>").arg(line);
        }

        // Newline inside <pre> is preserved.
        stream << line << "\n";
    }

    stream << "</pre>";

    // Prevent re-entrant updates while we setHtml()
    const QSignalBlocker blocker(m_textEdit);
    m_textEdit->setHtml(text);
}

void CodeView::highlightPC(uint32_t pc)
{
    if (m_currentPC == pc) return;
    m_currentPC = pc;

    // Update highlight markup
    updateDisplay();

    // After updating the HTML, scroll to the PC line.
    for (size_t i = 0; i < m_instructions.size(); i++) {
        if (m_instructions[i].address == pc) {
            QTextCursor cursor = m_textEdit->textCursor();
            cursor.movePosition(QTextCursor::Start);
            for (size_t j = 0; j < i; j++) {
                cursor.movePosition(QTextCursor::Down);
            }
            m_textEdit->setTextCursor(cursor);
            m_textEdit->ensureCursorVisible();
            break;
        }
    }
}

void CodeView::toggleBreakpoint(uint32_t address)
{
    auto it = std::find(m_breakpoints.begin(), m_breakpoints.end(), address);
    if (it != m_breakpoints.end()) {
        m_breakpoints.erase(it);
    } else {
        m_breakpoints.push_back(address);
    }
    
    // Update instruction breakpoint flags
    for (auto &instr : m_instructions) {
        instr.isBreakpoint = hasBreakpoint(instr.address);
    }
    
    updateDisplay();
    emit breakpointToggled(address);
}

bool CodeView::hasBreakpoint(uint32_t address)
{
    return std::find(m_breakpoints.begin(), m_breakpoints.end(), address) != m_breakpoints.end();
}

void CodeView::onTextEditClicked()
{
    // Handle click to toggle breakpoint
    QTextCursor cursor = m_textEdit->textCursor();
    int line = cursor.blockNumber();
    
    if (line >= 0 && line < static_cast<int>(m_instructions.size())) {
        toggleBreakpoint(m_instructions[line].address);
    }
}

void CodeView::setupSyntaxHighlighting()
{
    // Basic syntax highlighting can be added here
    // For now, we'll keep it simple
}

