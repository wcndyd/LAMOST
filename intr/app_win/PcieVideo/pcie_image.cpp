#include "pcie_image.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    setWindowIcon(QIcon(":/mainwindow/alientek.ico"));//设置状态栏图标
    this->setWindowTitle(tr("ALIENTEK PcieVideo V1.0"));
    ui->setupUi(this);

    image_h= 1024;
    image_v= 768;

    ui->text_h->setText(QString::number(image_h));
    ui->text_v->setText(QString::number(image_v));

    connect(&m_pcie_event_0, SIGNAL(sig_disp(int)), this, SLOT(disp_slot(int)));
    connect(&m_pcie_event_1, SIGNAL(sig_disp(int)), this, SLOT(disp_slot(int)));
    connect(&m_pcie_event_2, SIGNAL(sig_disp(int)), this, SLOT(disp_slot(int)));
    connect(&m_pcie_event_3, SIGNAL(sig_disp(int)), this, SLOT(disp_slot(int)));
    connect(&m_pcie_event_0, SIGNAL(finished()), this, SLOT(slotThreadFinish()));
    connect(&m_pcie_event_1, SIGNAL(finished()), this, SLOT(slotThreadFinish()));
    connect(&m_pcie_event_2, SIGNAL(finished()), this, SLOT(slotThreadFinish()));
    connect(&m_pcie_event_3, SIGNAL(finished()), this, SLOT(slotThreadFinish()));

    if (pcie_init()<0)
    {
        QMessageBox::information(this, "error", "init error.");
        ui->pushButton->setEnabled(false);
    }
}

MainWindow::~MainWindow()
{
    m_pcie_event_0.isrun=false;
    m_pcie_event_1.isrun=false;
    m_pcie_event_2.isrun=false;
    m_pcie_event_3.isrun=false;
    while (m_pcie_event_0.isrun||m_pcie_event_1.isrun||m_pcie_event_2.isrun||m_pcie_event_3.isrun);
    pcie_deinit();
    delete ui;
}

void MainWindow::disp_slot(int id)
{
    if(!m_pcie_event_0.isrun)
        return;

    ui->text_fps->setText(QString::number(c2h_transfer(image_h*image_v*4, id))+"fps");

    QPixmap pixmap = QPixmap::fromImage(*m_image,Qt::AutoColor);
    pixmap=pixmap.scaled(ui->label->width()/8*8,ui->label->height()/8*8,Qt::IgnoreAspectRatio,Qt::FastTransformation);
    ui->label->setPixmap(pixmap);
}

void MainWindow::slotThreadFinish()
{
    if(m_pcie_event_0.isRunning()||m_pcie_event_1.isRunning()||m_pcie_event_2.isRunning()||m_pcie_event_3.isRunning())
        return;
    m_state=0;
    ui->pushButton->setText(tr("开始"));
}


void MainWindow::on_pushButton_clicked()
{
    if(m_state==0)
    {
        image_h = ui->text_h->text().toUInt();
        image_v = ui->text_v->text().toUInt();
        m_image = new QImage(c2h_align_mem_tmp,image_h,image_v,QImage::Format_RGB32);
        pcie_start();
        if(!m_pcie_event_0.isRunning())
            m_pcie_event_0.start();
        if(!m_pcie_event_1.isRunning())
            m_pcie_event_1.start();
        if(!m_pcie_event_2.isRunning())
            m_pcie_event_2.start();
        if(!m_pcie_event_3.isRunning())
            m_pcie_event_3.start();
        m_state=1;
        ui->pushButton->setText(tr("停止"));
    }else{
        m_state=2;
        pcie_close();
        m_pcie_event_0.isrun=false;
        m_pcie_event_1.isrun=false;
        m_pcie_event_2.isrun=false;
        m_pcie_event_3.isrun=false;
    }
}
