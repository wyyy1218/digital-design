#ifndef CODE_VIEW_H
#define CODE_VIEW_H

#include <QWidget>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QLabel>
#include <QScrollBar>
#include <cstdint>
#include <vector>

struct Instruction {
    uint32_t address;
    uint32_t machineCode;
    QString assembly;
    bool isBreakpoint;
};

class CodeView : public QWidget
{
    Q_OBJECT

public:
    explicit CodeView(QWidget *parent = nullptr);
    void loadInstructions();
    void highlightPC(uint32_t pc);
    void updateDisplay();
    void toggleBreakpoint(uint32_t address);
    bool hasBreakpoint(uint32_t address);

signals:
    void breakpointToggled(uint32_t address);

private slots:
    void onTextEditClicked();

private:
    void setupSyntaxHighlighting();
    void parseInstructionFile();
    QString disassembleInstruction(uint32_t pc, uint32_t code);

    QTextEdit *m_textEdit;
    QLabel *m_titleLabel;
    std::vector<Instruction> m_instructions;
    uint32_t m_currentPC;
    std::vector<uint32_t> m_breakpoints;
};

#endif // CODE_VIEW_H

