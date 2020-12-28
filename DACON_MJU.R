#������ ����
#YM : ���س��
#SIDO : ������з���
#SIGUNGU : �����ߺз���
#FranClass : �һ���α���
#Type : ������
#Time : �ð���
#TotalSpent : �ѻ��ݾ�
#DisSpent : �糭������ ���ݾ�
#NumOfSpent : �� �̿�Ǽ�
#NumOfDisSpent : �� �糭������ �̿�Ǽ�
#POINT_X, POINT_Y : X,Y ��ǥ

install.packages('https://cran.r-project.org/src/contrib/Archive/rgdal/rgdal_1.3-9.tar.gz',repos=NULL,type="source")
install.packages('rvest')
install.packages("ggmap")
install.packages('maps')
install.packages('devtools')
install_github('dkahle/ggmap')
library(ggplot2)
library(RColorBrewer)
library(dplyr)
library(devtools)
library(rvest)
library(maps)
library(ggmap)
library(raster)
library(rgeos)
library(maptools)
library(rgdal)
library(gridExtra)

a <- read.csv("KRI-DAC_Jeju_data5.csv")
b <- read.csv("KRI-DAC_Jeju_data6.csv")
c <- read.csv("KRI-DAC_Jeju_data7.csv")
d <- read.csv("KRI-DAC_Jeju_data8.csv")

c <- c[,-c(6,7)]

ab <- rbind(a,b)
cd <- rbind(c,d)
df <- rbind(ab,cd)
sum(is.na(df)) # ����ġ ���� 0�̹Ƿ� ����ġ�� ���� ������ �ľ�!

df1 <- filter(df,Time!="x��")
head(df1)


#################################################
#x:�� y: �Ѿ�
by_YM <- group_by(df1,YM)
data1 <-summarise(by_YM,YM_total=sum(TotalSpent/100000000))
A1<-ggplot(data=data1,mapping=aes(x=YM,y=YM_total,fill=as.factor(YM)))+
  geom_bar(stat="identity")+

labs(
  title="5��~8�� �� ���ݾ�",
  x="���س��",
  y="�� ���ݾ�(���� : ���)", 
  fill="���س��"
  )

#x:�� y:������
by_YM <- group_by(df1,YM)
data2 <-summarise(by_YM,YM_Dis=sum(DisSpent/100000000))

A2<-ggplot(data=data2 ,mapping=aes(x=YM,y=YM_Dis,fill=as.factor(YM)))+
  geom_bar(stat="identity")+
  labs(
    title="5��~8�� �糭������ ���ݾ�",
    x="���س��",
    y="�糭������ �� ���ݾ�(���� : ���)",
    fill="���س��"
  )
grid.arrange(A1,A2,ncol=2)

##################################################### ----------1��

# �ð��뺰 
# ��ü 
by_Time <- group_by(df1,Time)
data4 <-summarise(by_Time,total_time=sum(TotalSpent))
B1 <- ggplot(data=data4,mapping=aes(x=Time,y=(total_time/1000000000), fill =Time))+
  geom_bar(stat="identity")+
  labs(
    title="�ð��뺰 �� ���ݾ� ����",
    x="�ð�",
    y="�� ���ݾ�(���� : ���)"
  )+theme(legend.position = "none")

#�糭������
data5 <-summarise(by_Time,total_time=sum(DisSpent))
B2 <- ggplot(data=data5,mapping=aes(x=Time,y=(total_time/1000000000), fill =Time))+
  geom_bar(stat="identity")+
  labs(
    title="�ð��뺰 �� �糭�����ݾ� ����",
    x="�ð�",
    y="�� ���ݾ�(���� : ���)"
  )+theme(legend.position = "none")

grid.arrange(B1, B2, nrow = 2)


###################################################### ------------2��

# ���浵�� �ٲٴ� �Լ�
convertCoordSystem <- function(long, lat, from.crs, to.crs){
  xy <- data.frame(long=long, lat=lat)
  coordinates(xy) <- ~long+lat
  
  from.crs <- CRS(from.crs)
  from.coordinates <- SpatialPoints(xy, proj4string=from.crs)
  
  to.crs <- CRS(to.crs)
  changed <- as.data.frame(SpatialPoints(spTransform(from.coordinates, to.crs)))
  names(changed) <- c("long", "lat")
  
  return(changed)
}

df_l <- df1[ , c('POINT_X', 'POINT_Y')]
from.crs = "+proj=tmerc +lat_0=38 +lon_0=127.5 +k=0.9996 +x_0=1000000 +y_0=2000000 +ellps=GRS80 +units=m +no_defs"

to.crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
df_l <- cbind(df_l, convertCoordSystem(df_l$POINT_X, df_l$POINT_Y, from.crs, to.crs))
df_s <- df_l[ , c('long', 'lat')]
head(df_s)
head(df_s)
df1[ , c('POINT_X', 'POINT_Y')] <- df_s
################################################################### �����浵 ��ȯ�Ϸ�

# �����ð�ȭ �糭������
df_DisSpent <- df1[, c('DisSpent', 'POINT_X', 'POINT_Y')] # ��ġ�� �糭������ ��� ����
head(df_DisSpent)
g1 <- ggmap(get_map(location='Hallasan National Park', zoom=10)) +
  stat_density_2d(data=df_DisSpent, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28)+
  labs(title = '��ġ�� �糭������ ��� ������')
g1<- g1 + scale_fill_gradient(low='yellow', high='red')
g1 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

####################################################### ���� �ð�ȭ �Ϸ�
# Type�� �ѻ��ݾ׺��� �糭������ ���� 10

df2<- df1[df1$NumofDisSpent>0,]
by_Type<-group_by(df2,Type)
by_typetotal<-summarise(by_Type,total_type=sum(DisSpent/Sum_total))
rank_type10<-arrange(by_typetotal, desc(total_type)) %>% slice(1:10)
unique(rank_type10$Type) # Type���Ȯ��
s1 <- ggplot(data=rank_type10,mapping=aes(x=reorder(Type,-total_type),y=total_type, fill=Type))+
  geom_bar(stat="identity")+
  labs(title="Type�� ��ü �� ���ݾ� ��� �糭������ ���� 10�� �׸�",x='Type',y='�ѻ��ݾ� ��� �糭������',
       subtitle="�糭������/�ѻ��ݾ�",fill="Type")

#Type�� �ѻ��ݾ׺��� �糭������ ���� 10

rank_typeworst10<-arrange(by_typetotal, total_type) %>% slice(1:10)
unique(rank_typeworst10$Type)
s2 <- ggplot(data=rank_typeworst10,mapping=aes(x=reorder(Type,-total_type),y=total_type, fill=Type))+
  geom_bar(stat="identity")+
  labs(title="Type�� ��ü �� ���ݾ� ��� �糭������ ���� 10�� �׸�",x='Type',y='�ѻ��ݾ� ��� �糭������',
       subtitle="�糭������/�ѻ��ݾ�",fill="Type")

grid.arrange(s1, s2, nrow = 2)
###################################################### ��ü ���� ���� 10��/ ���� 10�� �ð�ȭ �Ϸ�

df1$Sum_total<-sum(df1$TotalSpent)
by_Fran<-group_by(df1,FranClass)
data3<-summarise(by_Fran,prop_Dis = sum(DisSpent/Sum_total))
ggplot(data=data3,mapping=aes(x="",y=prop_Dis,fill=FranClass))+
  geom_bar(stat="identity")+
  coord_polar("y")+
  geom_text(aes(label= paste0(round(prop_Dis*18.86*100,1), "%")),
            position = position_stack(vjust = 0.5))+
  theme_void()+
  labs(
    title="��ü �� ���ݾ� ��� �糭 ������ ������",
    x="�һ���� ����",
    y="������",
    fill="�һ���� ����"
  )
######################################################�� ���ݾ� ��� �糭 ������ ������ �Ϸ�
asd <- df1 %>% group_by(FranClass) %>% count()
asd1 <- filter(asd, FranClass %in% c("����", "�Ϲ�"))
ggplot(data=asd1,mapping=aes(x='', y = n, fill=FranClass))+
  geom_bar(stat="identity")+
  geom_text(aes(label= paste0(round(n/sum(n) * 100,1), "%")),
            position = position_stack(vjust = 0.5))+
  coord_polar('y')+
  theme_void()+
  labs(
    title="������ �Ϲ��� �ŷ� Ƚ�� ����",
    x=" n ",
    y="������",
    fill=" ���� �� �Ϲ��� �ŷ� Ƚ�� ����"
  )
################################################################ ������ �Ϲ��� �ŷ� Ƚ�� ����

#�Ϲ� ����10�� �̾� �ѻ��ݾ�
df5<- df1[df1$FranClass =="�Ϲ�", ]
by_Type5 <- group_by(df5,Type)
by_typetotal5 <-summarise(by_Type5,total5=sum(TotalSpent))

rank_type105<-arrange(by_typetotal5, desc(total5))%>% slice(1:10)
C1 <- ggplot(data=rank_type105,mapping=aes(x=reorder(Type,-total5),y=total5, fill = Type))+
  geom_bar(stat="identity") +
  coord_polar()+labs(
    title="�Ϲݿ����� �� ���ݾ��� ���� ���� 10�� �׸�",
    x="Type",
    y="���ݾ�",
    fill="Type"
  )
  
#�Ϲ� ����10�� �̾� �ѻ��ݾ�

rank_worsttype105<-arrange(by_typetotal5, total5)%>% slice(1:10)
C3 <- ggplot(data=rank_worsttype105,mapping=aes(x=reorder(Type,-total5),y=total5,fill=Type))+
  geom_bar(stat="identity") +
  coord_polar()+labs(
    title="�Ϲݿ����� �� ���ݾ��� ���� ���� 10�� �׸�",
    x="Type",
    y="���ݾ�",
    fill="Type"
  )

#���� ����10�� �̾� �ѻ��ݾ�
df6<- df1[df1$FranClass =="����", ]
by_Type6 <- group_by(df6,Type)
by_typetotal6 <-summarise(by_Type6,total6=sum(TotalSpent))

rank_type106<-arrange(by_typetotal6, desc(total6))%>% slice(1:10)
C2 <- ggplot(data=rank_type106,mapping=aes(x=reorder(Type,-total6),y=total6,fill=Type))+
  geom_bar(stat="identity")+
  coord_polar()+labs(
    title="���������� �� ���ݾ��� ���� ���� 10�� �׸�",
    x="Type",
    y="���ݾ�",
    fill="Type"
  )


#���� ����10�� �̾� �ѻ��ݾ�

rank_worsttype106<-arrange(by_typetotal6, total6)%>% slice(1:10)
C4 <- ggplot(data=rank_worsttype106,mapping=aes(x=reorder(Type,-total6),y=total6,fill=Type))+
  geom_bar(stat="identity")+
  coord_polar()+labs(
    title="���������� �� ���ݾ��� ���� ���� 10�� �׸�",
    x="Type",
    y="���ݾ�",
    fill="Type"
  )

grid.arrange(C1, C2, C3, C4, nrow = 2, ncol = 2)
######################################################################### �Ϲ�, ���� �ѻ��ݾ� �� �ð�ȭ �Ϸ�

#�Ϲ� �糭������ ��� ���� 10

by_Type2<-group_by(df2,Type)
by_typetotal2<-summarise(by_Type2,total_type=sum(DisSpent/Sum_total))
rank_type10<-arrange(by_typetotal2, desc(total_type)) %>% slice(1:10)
unique(rank_type10$Type)
D1 <- ggplot(data=rank_type10,mapping=aes(x=reorder(Type,total_type),y=total_type, fill=Type))+
  geom_bar(stat="identity")+
  coord_flip()+labs(title="�Ϲݿ����� Type �� �糭������ ���� ���� 10�� �׸�",x='Type',y='�糭������ ��� ����',
       subtitle="�� ���ݾ� ���� �糭������ ����",fill="Type")

#��ü �糭������ ��� ���� 10��
rank_typeworst10<-arrange(by_typetotal2, total_type) %>% slice(1:10)
unique(rank_typeworst10$Type)
D3 <- ggplot(data=rank_typeworst10,mapping=aes(x=reorder(Type,total_type),y=total_type, fill=Type))+
  geom_bar(stat="identity")+
  coord_flip()+labs(title="�Ϲݿ����� Type �� �糭������ ���� ���� 10�� �׸�",x='Type',y='�糭������ ��� ���� ',
       subtitle="�� ���ݾ� ���� �糭������ ����",fill="Type")


#���� �糭������ ���� 10��
df2<- df1[df1$NumofDisSpent>0,]
df3<- df2[df2$FranClass == "����", ]
by_Type3<-group_by(df3,Type)
by_typetotal3<-summarise(by_Type3,total_type=sum(DisSpent/Sum_total))
rank_type103<-arrange(by_typetotal3, desc(total_type)) %>% slice(1:10)
D2 <- ggplot(data=rank_type103,mapping=aes(x=reorder(Type,total_type),y=total_type, fill=Type))+
  geom_bar(stat="identity")+
  coord_flip()+
  labs(title="���������� Type �� �糭������ ���� ���� 10�� �׸�",x='Type',y='�糭������ ��� ����',
       subtitle="�� ���ݾ� ���� �糭������ ����",fill="Type")


#���� �糭������ ���� 10��
df3<- df2[df2$FranClass == "����", ]
by_Type3<-group_by(df3,Type)
by_typetotal3<-summarise(by_Type3,total_type=sum(DisSpent/Sum_total))
rank_typeworst103<-arrange(by_typetotal3, total_type) %>% slice(1:10)
unique(rank_typeworst103$Type)
D4 <- ggplot(data=rank_typeworst103,mapping=aes(x=reorder(Type,total_type),y=total_type, fill=Type))+
  geom_bar(stat="identity")+
  coord_flip()+
  labs(title="���������� Type �� �糭������ ���� ���� 10�� �׸�",x='Type',y='�糭������ ��� ����',
       subtitle="�� ���ݾ� ���� �糭������ ����",fill="Type")

grid.arrange(D1, D2, D3, D4, nrow = 2, ncol = 2)

########################################################################## �� ���ݾ��� ���� �糭������ ���� �ð�ȭ �Ϸ�
# �Ϲݿ��� ���۸��� ��ǥ ���
dd1 <- filter(df1, FranClass %in% '�Ϲ�')
dd1 <- filter(dd1, Type %in% '���۸���')
dd1 <- dd1[ , c('Type', 'POINT_X', 'POINT_Y')]

dd1_market1 <- ggmap(get_map(location='Hallasan National Park', zoom=10)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '�Ϲݿ����� ���۸��� ���� ����')
dd1_market1 <- dd1_market1 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

dd1_market2 <- ggmap(get_map(location='jeju', zoom=12)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '�Ϲݿ����� ���۸��� ���� ���� (���ֽ� ���� ������)')
dd1_market2 <- dd1_market2 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)


dd1_market3 <- ggmap(get_map(location='seogwipo', zoom=12)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '�Ϲݿ����� ���۸��� ���� ���� (�������� ���� ������)')
dd1_market3 <- dd1_market3 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)


grid.arrange(dd1_market1, dd1_market2, dd1_market3, ncol = 3)
# ------------------------------------------------------------
# �������� ���۸��� ��ǥ ���
dd1 <- filter(df1, FranClass %in% '����')
dd1 <- filter(dd1, Type %in% '���۸���')
dd1 <- dd1[ , c('Type', 'POINT_X', 'POINT_Y')]

dd1_market1 <- ggmap(get_map(location='Hallasan National Park', zoom=10)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '���������� ���۸��� ���� ����')
dd1_market1 <- dd1_market1 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

dd1_market2 <- ggmap(get_map(location='jeju', zoom=12)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '���������� ���۸��� ���� ���� (���ֽ� ���� ������)')
dd1_market2 <- dd1_market2 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

dd1_market3 <- ggmap(get_map(location='seogwipo', zoom=12)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '���������� ���۸��� ���� ���� (�������� ���� ������)')
dd1_market3 <- dd1_market3 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

grid.arrange(dd1_market1, dd1_market2, dd1_market3, ncol = 3)
###################################################################### ���۸��� ���� �Ϸ�

# �Ϲݿ��� �Ϲ��ѽ� ��ǥ ���
dd1 <- filter(df1, FranClass %in% '�Ϲ�')
dd1 <- filter(dd1, Type %in% '�Ϲ��ѽ�')
dd1 <- dd1[ , c('Type', 'POINT_X', 'POINT_Y')]

dd1_market1 <- ggmap(get_map(location='Hallasan National Park', zoom=10)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '�Ϲݿ����� �Ϲ��ѽ� ���� ����')
dd1_market1 <- dd1_market1 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

dd1_market2 <- ggmap(get_map(location='jeju', zoom=12)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '�Ϲݿ����� �Ϲ��ѽ� ���� ���� (���ֽ� ���� ������)')
dd1_market2 <- dd1_market2 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

dd1_market3 <- ggmap(get_map(location='seogwipo', zoom=12)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '�Ϲݿ����� �Ϲ��ѽ� ���� ���� (�������� ���� ������)')
dd1_market3 <- dd1_market3 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

grid.arrange(dd1_market1, dd1_market2, dd1_market3, ncol = 3)
# -------------------------------------------------------------
# �������� �Ϲ��ѽ� ��ǥ ���
dd1 <- filter(df1, FranClass %in% '����')
dd1 <- filter(dd1, Type %in% '�Ϲ��ѽ�')
dd1 <- dd1[ , c('Type', 'POINT_X', 'POINT_Y')]

dd1_market1 <- ggmap(get_map(location='Hallasan National Park', zoom=10)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '���������� �Ϲ��ѽ� ���� ����')
dd1_market1 <- dd1_market1 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

dd1_market2 <- ggmap(get_map(location='jeju', zoom=12)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '���������� �Ϲ��ѽ� ���� ���� (���ֽ� ���� ������)')
dd1_market2 <- dd1_market2 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

dd1_market3 <- ggmap(get_map(location='seogwipo', zoom=12)) +
  stat_density_2d(data=dd1, aes(x=POINT_X, y=POINT_Y, fill=..level.., alpha=..level..), geom='polygon', size=7, bins=28) +
  labs(title = '���������� �Ϲ��ѽ� ���� ���� (�������� ���� ������)')
dd1_market3 <- dd1_market3 + scale_fill_gradient(low='yellow', high='red', guide=F) + scale_alpha(range=c(0.02, 0.8), guide=F)

grid.arrange(dd1_market1, dd1_market2, dd1_market3, ncol = 3)