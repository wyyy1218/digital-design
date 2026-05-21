#include "control_panel.h"
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QLabel>

ControlPanel::ControlPanel(QWidget *parent)
    : QWidget(parent), m_running(false)
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    
    m_loadButton = new QPushButton("Load", this);
    m_runButton = new QPushButton("Run", this);
    m_pauseButton = new QPushButton("Pause", this);
    m_stepButton = new QPushButton("Step", this);
    m_resetButton = new QPushButton("Reset", this);
    
    m_pauseButton->setEnabled(false);
    
    buttonLayout->addWidget(m_loadButton);
    buttonLayout->addWidget(m_runButton);
    buttonLayout->addWidget(m_pauseButton);
    buttonLayout->addWidget(m_stepButton);
    buttonLayout->addWidget(m_resetButton);
    buttonLayout->addStretch();
    
    QHBoxLayout *stepNLayout = new QHBoxLayout();
    stepNLayout->addWidget(new QLabel("Step N:", this));
    m_stepNSpinBox = new QSpinBox(this);
    m_stepNSpinBox->setMinimum(1);
    m_stepNSpinBox->setMaximum(10000);
    m_stepNSpinBox->setValue(1);
    m_stepNButton = new QPushButton("Step N", this);
    stepNLayout->addWidget(m_stepNSpinBox);
    stepNLayout->addWidget(m_stepNButton);
    stepNLayout->addStretch();
    
    mainLayout->addLayout(buttonLayout);
    mainLayout->addLayout(stepNLayout);
    
    setLayout(mainLayout);
    
    // Connect signals
    connect(m_loadButton, &QPushButton::clicked, this, &ControlPanel::loadClicked);
    connect(m_runButton, &QPushButton::clicked, this, &ControlPanel::runClicked);
    connect(m_pauseButton, &QPushButton::clicked, this, &ControlPanel::pauseClicked);
    connect(m_stepButton, &QPushButton::clicked, this, &ControlPanel::stepClicked);
    connect(m_resetButton, &QPushButton::clicked, this, &ControlPanel::resetClicked);
    connect(m_stepNButton, &QPushButton::clicked, this, [this]() {
        emit stepNClicked(m_stepNSpinBox->value());
    });
    connect(m_stepNSpinBox, QOverload<int>::of(&QSpinBox::valueChanged),
            this, &ControlPanel::onStepNValueChanged);
}

void ControlPanel::onStepNValueChanged(int value)
{
    // This slot is connected but doesn't need to do anything
    // The value is read when the button is clicked
    Q_UNUSED(value);
}

void ControlPanel::setRunning(bool running)
{
    m_running = running;
    m_runButton->setEnabled(!running);
    m_pauseButton->setEnabled(running);
    m_stepButton->setEnabled(!running);
    m_stepNButton->setEnabled(!running);
}

