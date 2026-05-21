#include "main_window.h"
#include "register_view.h"
#include "code_view.h"
#include "memory_view.h"
#include "control_panel.h"
#include "watchpoint_dialog.h"
#include "temu_wrapper.h"
#include <QMenuBar>
#include <QToolBar>
#include <QStatusBar>
#include <QSplitter>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QMessageBox>
#include <QFileDialog>
#include <QInputDialog>
#include <QTimer>
#include <QLabel>
#include <cstdlib>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), m_programLoaded(false), m_instructionCount(0)
{
    setWindowTitle("TEMU - LoongArch32 Instruction Set Simulator");
    setMinimumSize(1200, 800);

    // Create views
    m_registerView = new RegisterView(this);
    m_codeView = new CodeView(this);
    m_memoryView = new MemoryView(this);
    m_controlPanel = new ControlPanel(this);

    setupMenus();
    setupToolbar();
    setupStatusBar();
    setupLayout();
    setupConnections();

    // Setup update timer
    m_updateTimer = new QTimer(this);
    connect(m_updateTimer, &QTimer::timeout, this, &MainWindow::updateViews);
    m_updateTimer->start(100); // Update every 100ms

    // Initialize TEMU (with dummy args for now)
    char *argv[] = {const_cast<char*>("temu_gui"), nullptr};
    temu_init(1, argv);

    // Initialize instruction count
    m_instructionCount = 0;
}

MainWindow::~MainWindow()
{
}

void MainWindow::setupMenus()
{
    // File menu
    QMenu *fileMenu = menuBar()->addMenu("&File");
    m_loadAction = fileMenu->addAction("&Load Program...", this, &MainWindow::onLoadProgram);
    m_loadAction->setShortcut(QKeySequence::Open);
    m_exitAction = fileMenu->addAction("E&xit", this, &QWidget::close);
    m_exitAction->setShortcut(QKeySequence::Quit);

    // Run menu
    QMenu *runMenu = menuBar()->addMenu("&Run");
    m_runAction = runMenu->addAction("&Run", this, &MainWindow::onRun);
    m_runAction->setShortcut(Qt::Key_F5);
    m_pauseAction = runMenu->addAction("&Pause", this, &MainWindow::onPause);
    m_pauseAction->setShortcut(Qt::Key_F6);
    m_stepAction = runMenu->addAction("&Step", this, &MainWindow::onStep);
    m_stepAction->setShortcut(Qt::Key_F10);
    m_stepNAction = runMenu->addAction("Step &N...", this, &MainWindow::onStepN);
    m_resetAction = runMenu->addAction("&Reset", this, &MainWindow::onReset);
    m_resetAction->setShortcut(Qt::Key_F9);

    // Debug menu
    QMenu *debugMenu = menuBar()->addMenu("&Debug");
    m_watchpointsAction = debugMenu->addAction("&Watchpoints...", this, &MainWindow::onWatchpoints);
    m_evalExprAction = debugMenu->addAction("&Evaluate Expression...", this, &MainWindow::onEvaluateExpr);
    m_evalExprAction->setShortcut(Qt::CTRL | Qt::Key_E);

    // Help menu
    QMenu *helpMenu = menuBar()->addMenu("&Help");
    m_aboutAction = helpMenu->addAction("&About", this, &MainWindow::onAbout);
}

void MainWindow::setupToolbar()
{
    QToolBar *toolbar = addToolBar("Main");
    toolbar->addAction(m_loadAction);
    toolbar->addSeparator();
    toolbar->addAction(m_runAction);
    toolbar->addAction(m_pauseAction);
    toolbar->addAction(m_stepAction);
    toolbar->addAction(m_resetAction);
    toolbar->addSeparator();
    toolbar->addAction(m_watchpointsAction);
    toolbar->addAction(m_evalExprAction);
}

void MainWindow::setupStatusBar()
{
    statusBar()->showMessage("Ready - Click 'Load' to load a program");
}

void MainWindow::setupLayout()
{
    QWidget *centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);

    // Only one layout per widget - use VBoxLayout for vertical arrangement
    QVBoxLayout *outerLayout = new QVBoxLayout(centralWidget);
    outerLayout->setContentsMargins(5, 5, 5, 5);
    outerLayout->setSpacing(5);

    // Main splitter for register view and code/memory views
    m_mainSplitter = new QSplitter(Qt::Horizontal, this);
    m_mainSplitter->addWidget(m_registerView);

    // Right: Splitter for code and memory
    m_rightSplitter = new QSplitter(Qt::Vertical, this);
    m_rightSplitter->addWidget(m_codeView);
    m_rightSplitter->addWidget(m_memoryView);
    m_rightSplitter->setStretchFactor(0, 2);
    m_rightSplitter->setStretchFactor(1, 1);

    m_mainSplitter->addWidget(m_rightSplitter);
    m_mainSplitter->setStretchFactor(0, 1);
    m_mainSplitter->setStretchFactor(1, 3);

    outerLayout->addWidget(m_mainSplitter);

    // Control panel at bottom
    outerLayout->addWidget(m_controlPanel);
    outerLayout->setStretch(0, 1);
    outerLayout->setStretch(1, 0);
}

void MainWindow::setupConnections()
{
    connect(m_controlPanel, &ControlPanel::loadClicked, this, &MainWindow::onLoadProgram);
    connect(m_controlPanel, &ControlPanel::runClicked, this, &MainWindow::onRun);
    connect(m_controlPanel, &ControlPanel::pauseClicked, this, &MainWindow::onPause);
    connect(m_controlPanel, &ControlPanel::stepClicked, this, &MainWindow::onStep);
    connect(m_controlPanel, &ControlPanel::stepNClicked, this, &MainWindow::onStepN);
    connect(m_controlPanel, &ControlPanel::resetClicked, this, &MainWindow::onReset);
}

void MainWindow::updateViews()
{
    if (!m_programLoaded) return;

    // Update register view
    m_registerView->updateRegisters();

    // Update code view (highlight PC)
    uint32_t pc = temu_get_pc();
    m_codeView->highlightPC(pc);

    // Update memory view
    m_memoryView->updateMemory();

    // Update status bar
    int state = temu_get_state();
    QString stateStr = (state == 0) ? "STOP" : (state == 1) ? "RUNNING" : "END";
    statusBar()->showMessage(
        QString("PC: 0x%1 | State: %2 | Instructions: %3")
            .arg(pc, 8, 16, QChar('0'))
            .arg(stateStr)
            .arg(m_instructionCount));
}

void MainWindow::onLoadProgram()
{
    loadProgramFiles();
}

void MainWindow::loadProgramFiles()
{
    QFile instFile("inst.bin");
    QFile dataFile("data.bin");

    if (!instFile.exists()) {
        QMessageBox::warning(this, "File Not Found",
                             "inst.bin not found. Please compile your program first.\n\n"
                             "Run: cd loongarch_sc && make");
        return;
    }

    if (!dataFile.exists()) {
        QMessageBox::warning(this, "File Not Found",
                             "data.bin not found. Please compile your program first.\n\n"
                             "Run: cd loongarch_sc && make");
        return;
    }

    temu_restart();

    // Load instructions into code view
    m_codeView->loadInstructions();

    m_programLoaded = true;
    m_instructionCount = 0;
    statusBar()->showMessage("Program loaded successfully - Ready to run");
    updateViews();
}

void MainWindow::onRun()
{
    if (!m_programLoaded) {
        QMessageBox::information(this, "No Program", "Please load a program first (File → Load Program).");
        return;
    }

    m_controlPanel->setRunning(true);

    // Run until breakpoint/watchpoint/end
    temu_execute(-1);

    m_controlPanel->setRunning(false);

    // If watchpoint triggered, show a clear status message
    if (temu_check_watchpoints()) {
        statusBar()->showMessage("STOP - Watchpoint triggered");
    }

    updateViews();
}

void MainWindow::onPause()
{
    m_controlPanel->setRunning(false);
}

void MainWindow::onStep()
{
    if (!m_programLoaded) {
        QMessageBox::information(this, "No Program", "Please load a program first (File → Load Program).");
        return;
    }

    temu_execute(1);
    m_instructionCount++;

    if (temu_check_watchpoints()) {
        statusBar()->showMessage("STOP - Watchpoint triggered");
    }

    updateViews();
}

void MainWindow::onStepN()
{
    bool ok;
    int n = QInputDialog::getInt(this, "Step N Instructions",
                                "Number of instructions:", 1, 1, 10000, 1, &ok);
    if (!ok) return;

    if (!m_programLoaded) {
        QMessageBox::information(this, "No Program", "Please load a program first (File → Load Program).");
        return;
    }

    temu_execute(n);
    m_instructionCount += n;

    if (temu_check_watchpoints()) {
        statusBar()->showMessage("STOP - Watchpoint triggered");
    }

    updateViews();
}

void MainWindow::onReset()
{
    if (!m_programLoaded) {
        QMessageBox::information(this, "No Program", "Please load a program first (File → Load Program).");
        return;
    }

    temu_restart();
    m_instructionCount = 0;
    m_codeView->loadInstructions();
    updateViews();
    statusBar()->showMessage("Program reset - Ready to run");
}

void MainWindow::onWatchpoints()
{
    WatchpointDialog dialog(this);

    // Update main status bar when watchpoint list changes
    connect(&dialog, &WatchpointDialog::watchpointsChanged, this, [this]() {
        statusBar()->showMessage("Watchpoints updated");
    });

    dialog.exec();
}

void MainWindow::onEvaluateExpr()
{
    bool ok;
    QString expr = QInputDialog::getText(this, "Evaluate Expression",
                                        "Enter expression:", QLineEdit::Normal,
                                        "", &ok);
    if (ok && !expr.isEmpty()) {
        int success = 0;
        uint32_t result = temu_eval_expr(expr.toLocal8Bit().constData(), &success);

        if (success) {
            QMessageBox::information(this, "Result",
                                     QString("Expression: %1\n\nResult:\n0x%2\n(%3)")
                                         .arg(expr)
                                         .arg(result, 8, 16, QChar('0'))
                                         .arg(result));
        } else {
            QMessageBox::warning(this, "Error", "Failed to evaluate expression.\n\nCheck syntax and try again.");
        }
    }
}

void MainWindow::onAbout()
{
    QMessageBox::about(this, "About TEMU",
                       "TEMU - LoongArch32 Instruction Set Simulator\n\n"
                       "A graphical interface for the TEMU simulator.\n"
                       "Based on Qt framework.\n\n"
                       "Version 1.0");
}
