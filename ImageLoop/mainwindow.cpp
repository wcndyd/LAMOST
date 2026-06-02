#include "mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    this->setWindowTitle(tr("ALIENTEK ImageLoop V1.0"));
    pcie_init();
}


MainWindow::~MainWindow()
{
    delete ui;
    pcie_deinit();
}

void MainWindow::on_pushButton_clicked()
{
    QPixmap m_Qpixmap;
    QString filename = QFileDialog::getOpenFileName(this,"Select BMP or BIN File","","Image (*.bmp *.bin)");
    if(filename.isEmpty())
        return;
    download_image_data(filename.toLatin1().data());
    QImage image(filename);
    m_Qpixmap=QPixmap::fromImage(image,Qt::AutoColor);
    m_Qpixmap=m_Qpixmap.scaled(ui->label1->width()/8*8,ui->label1->height()/8*8,Qt::IgnoreAspectRatio,Qt::FastTransformation);
    ui->label1->setPixmap(m_Qpixmap);
}

void MainWindow::on_pushButton_2_clicked()
{
    QPixmap m_Qpixmap;
    QImage *m_Qimage = new QImage(c2h_align_mem_tmp,image_h,image_v,QImage::Format_RGB32);
    c2h_transfer(0x30000000,image_h*image_v*4,c2h_align_mem_tmp);
    m_Qpixmap = QPixmap::fromImage(*m_Qimage,Qt::AutoColor);
    m_Qpixmap=m_Qpixmap.scaled(ui->label2->width()/8*8,ui->label2->height()/8*8,Qt::IgnoreAspectRatio,Qt::FastTransformation);
    ui->label2->setPixmap(m_Qpixmap);
}

void MainWindow::on_pushButton_3_clicked()
{
    QImage image;
    ui->label1->setPixmap(QPixmap::fromImage(image,Qt::AutoColor));
}

void MainWindow::on_pushButton_4_clicked()
{
    QImage image;
    ui->label2->setPixmap(QPixmap::fromImage(image,Qt::AutoColor));
}

