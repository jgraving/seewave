################################################################################
## Seewave by Jerome Sueur, Caroline Simonis & Thierry Aubin
## Contributors : Jonathan Fees, Martin Maechler, Sandrine Pavoine, Luis J. Villanueva-Rivera
## Acknowledgements: Michel Baylac, Emmanuel Paradis, Arnold Fertin, Kurt Hornik
################################################################################

################################################################################
##                                ADDSILW
################################################################################

addsilw<-function(
wave,
f,
at = "end",
choose = FALSE,
d = NULL,
plot = FALSE,
Sample = FALSE,
...)

{
input<-inputw(wave=wave,f=f); wave<-input$w; f<-input$f; rm(input)

if(at=="start")  at<-0
if(at=="middle") at<-nrow(wave)/(2*f)
if(at=="end")    at<-nrow(wave)/f

if(is.null(d)) stop("silence duration has to be set with the argument 'd'")

if(choose==TRUE)
  { 
	cat("choose position on the wave\n")
  if (.Platform$OS.type == "windows") flush.console()
  oscillo(wave,f=f)
	coord<-locator(n=1)
  at<-coord$x[1]; abline(v=at,col=2,lty=2)
	}

pos<-round(at*f)
wave1<-wave[1:pos,1]
sil<-rep(0,d*f)
wave2<-wave[-(1:pos),1]

wave3<-as.matrix(c(wave1,sil,wave2))
                               
if (plot == TRUE){oscillo(wave=wave3,f=f,...)}
else 
    {
    if (Sample == TRUE){wave3<-as.Sample(as.numeric(wave3), rate=f, bits=16)}
    return(wave3)
    }
}

################################################################################
##                                AFILTER                                       
################################################################################

afilter<-function(
wave,
f,
threshold = 5,
plot = TRUE,
listen = FALSE,
Sample = FALSE,
...
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

t1<-max(abs(wave))*(threshold/100)
wave1<-ifelse(abs(wave)<=t1,yes=0,no=1)
wave2<-as.matrix(wave[,1]*wave1[,1])
wave<-as.matrix(wave2)

if(plot==TRUE)
    {
    oscillo(wave=wave,f=f,...)
    if(listen == TRUE) {listen(wave,f=f)}
    }
else
    {
    if(Sample == TRUE) {wave<-as.Sample(as.numeric(wave), rate=f, bits=16)}
    if(listen == TRUE) {listen(wave,f=f)}
    return(wave)
    }
}

################################################################################
##                                AMA
################################################################################

ama<-function(
wave,
f,
envt = "hil",
wl = 512,
plot = TRUE,
type = "l",
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; F<-input$f ; rm(input)
enve<-env(wave=wave, f=f, envt = envt, plot = FALSE)
meanspec(wave=enve, f=f, wl=wl, plot=plot, type=type,...)
}


################################################################################
##                                ATTENUATION                                        
################################################################################

attenuation<-function
(
lref,
dref = 1,
dstop,
n,
plot = TRUE,
xlab = "Distance (m)",
ylab = "dB",
type="l",
...
)

{
data<-numeric(n)
step<-seq(dref,dstop,length.out=n)
{for(i in step){data[which(step==i)]<-lref-(20*log10(i/dref))}}

plot(x=step,y=data,xlab=xlab,ylab=ylab,type=type,...)
if(plot == FALSE) return(data)
}


################################################################################
##                                AUTOC                                         
################################################################################

autoc<-function(
wave,
f,
wl = 512,
fmax,
threshold = NULL,
plot = TRUE,
xlab = "Time (s)",
ylab = "Frequency (kHz)",
ylim = c(0,f/2000),
...)

{
cat("Please wait...\n")
if (.Platform$OS.type == "windows") flush.console()

input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

n<-nrow(wave)
step<-seq(1,n-wl,wl-(wl/100))
fmini<-round(wl*(fmax/(f/2)))

if(!is.null(threshold)) wave<-afilter(wave=wave,f=f,threshold=threshold,plot=FALSE)

# discards the two last windows because of the lag
N<-length(step)-1  
R<-matrix(data=numeric(wl*N),wl,N)

for (j in 1:N)
  {
  for (i in 1:wl)
    {  
    R[i,j]<-(1/(2*wl)+1)*sum(wave[step[j]:(step[j]+wl-1),1]
                              *wave[(step[j]+i):(step[j]+wl+i-1),1])
    }
  }

tfond<-numeric(N)
for (k in 1:N) {tfond[k]<-which.max(R[-c(fmini:wl),k])}
y0<-f/tfond/1000
y<-ifelse(y0==f/1000,yes=NA,no=y0)

x<-seq(0,n/f,length.out=N)  

if (plot == TRUE)
  {
  plot(x=x, y=y,
  xlab = xlab,
  ylab = ylab, ylim = ylim,
  las = 1,
  ...)
  }

else return(cbind(x,y))
}


################################################################################
##                                CCOH                                        
################################################################################

ccoh<-function(
wave1,
wave2,
f,
wl = 512,
ovlp = 0,
plot = TRUE,
grid = TRUE,
scale = TRUE,
cont = FALSE,
collevels = seq(0,1,0.01),
palette = rev.heat.colors,
contlevels = seq (0,1,0.01),
colcont = "black",
colbg = "white",
colgrid = "black",
colaxis = "black",
collab = "black",
plot.title =
    title(main = "", xlab = "Time (s)",
    ylab = "Frequency (kHz)"),
scalelab = "Coherence",
scalefontlab = 1,
scalecexlab =0.75,
axisX = TRUE,
axisY = TRUE,
flim = NULL,
flimd = NULL,
...)

{
input1<-inputw(wave=wave1,f=f) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
wave2<-inputw(wave=wave2,f=f)$w

n1<-nrow(wave1)
n2<-nrow(wave2)
if (n1 != n2) stop("'wave 1' and 'wave 2' must have the same length")
n<-n1


# dynamic vertical zoom (modifications of analysis parameters)
if (!is.null(flimd))
  {
  # zoom magnification
  mag<-round((f/2000)/(flimd[2]-flimd[1]))
  # new parameters
  wl<-wl*mag
  if (ovlp==0) ovlp<-100
  ovlp<-100-round(ovlp/mag)
  # use of normal flim for following axis modifications
  flim<-flimd
  }

step<-seq(1,n-wl,wl-(ovlp*wl/100))	# coherence windows

z1<-matrix(data=numeric((wl)*length(step)),wl,length(step))

for(i in step)
  {
  z1[,which(step==i)]<-spec.pgram(cbind(wave1[i:(wl+i-1),],
    wave2[i:(wl+i-1),]), spans = c(3,3), fast=FALSE, taper=FALSE, plot=FALSE)$coh
  }

z<-z1[1:(wl/2),]							  

# X axis settings
X<-seq(0,n/f,length.out=length(step))

# vertical zoom
if (is.null(flim)==TRUE)
  {
  Y<-seq(0,f/2000,length.out=nrow(z))
  }
else
  {
  fl1<-flim[1]*nrow(z)*2000/f
  fl2<-flim[2]*nrow(z)*2000/f
  z<-z[fl1:fl2,]
  Y<-seq(flim[1],flim[2],length.out=nrow(z))
  }
  
Z<-t(z)
   
if (plot==TRUE)
 	{
  Zlim<-range(Z, finite = TRUE) 
    
  if (scale==TRUE)
    {
    def.par <- par(no.readonly = TRUE)
    on.exit(par(def.par))
    layout(matrix(c(1, 2), nc = 2, byrow=TRUE), widths = c(6, 1))
    par(mar=c(5,4.1,1,0),las=1,cex=1,bg=colbg,col=colaxis,col.axis=colaxis,col.lab=collab)
    filled.contour.modif2(x=X ,y=Y, z=Z, levels=collevels, nlevels=20,
			plot.title=plot.title, color.palette=palette,axisX=axisX, axisY=axisY)
   	if (grid == TRUE) grid(nx=NA, ny=NULL, col=colgrid)
		if(colaxis != colgrid) abline(h=0,col=colaxis) else abline(h=0,col=colgrid)
    par(mar=c(5,1,4.5,3),las=0)
    dBscale(collevels=collevels,palette=palette,fontlab=scalefontlab,
      cexlab=scalecexlab,collab=collab,textlab=scalelab,colaxis=colaxis)
    }
  
  if (scale==FALSE)
   {
   par(las=1, col=colaxis, col.axis=colaxis, col.lab=collab,,bg=colbg,...)
   filled.contour.modif2(x=X ,y=Y, z=Z, levels=collevels, nlevels=20,
			plot.title=plot.title, color.palette=palette, axisX=axisX, axisY=axisY,
      col.lab=collab,colaxis=colaxis)		
   if (grid == TRUE) grid(nx=NA, ny=NULL, col=colgrid)
 	 if(colaxis != colgrid) abline(h=0,col=colaxis) else abline(h=0,col=colgrid)
   }

  if (cont==TRUE) 
	 {
   contour(X,Y,Z,add=TRUE,
	 levels=contlevels,nlevels=5,col=colcont,...)
	 }  
  }
else return(z)
}




################################################################################
##                                CEPS                                         
################################################################################

ceps<-function(
wave,
f,
wl = 512,
at = NULL,
from = NULL,
to = NULL,
tpeaks = NULL,     # peaks in time (s)
fpeaks = NULL,     # peaks in frequency (Hz)
tidentify = FALSE,   # identify in seconds
fidentify = FALSE,   # identify in Hz
col = "black",
cex = 1,
colpeaks = "red",
cexpeaks = 0.75,
fontpeaks = 1,
plot = TRUE,
qlab = "Quefrency (bottom: s, up: Hz)",
alab = "Amplitude",
qlim = NULL,
alim = NULL,
type= "l",
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(!is.null(from)|!is.null(to))
  {
  if(is.null(from) && !is.null(to)) {a<-1; b<-round(to*f)}
  if(!is.null(from) && is.null(to)) {a<-round(from*f); b<-length(wave)}
	if(!is.null(from) && !is.null(to))
		{
		if (from>to) stop("'from' cannot be superior to 'to'")
		if(from==0) {a<-1} else a<-round(from*f)
		b<-round(to*f)
		}
  wave<-as.matrix(wave[a:b,])
  }

if(!is.null(at))
  {
  if(wl==FALSE) stop("Argument 'wl' has to be set up, for instance wl=512")
  c<-round(at*f)
  wl2<-wl%/%2
  wave<-as.matrix(wave[(c-wl2):(c+wl2),])
  }

n<-nrow(wave)
N<-round(n/2)

z1<-Re(fft(log(abs(fft(wave[,1]))),inverse=TRUE))
z<-z1[1:N]

if(!is.null(tpeaks))
  {
  check.pks(z)
  p<-peaks(z,tpeaks)
  respeaks<-seq(z)[p]/f
  }

if(!is.null(fpeaks))
  {
  check.pks(z)
  p<-peaks(z,fpeaks)
  respeaks<-f/seq(z)[p]
  }

x<-seq(0,N/f,length.out=N)

if (plot == TRUE)
  {
  plot(x=x,y=z,
  xlab=qlab,xaxt="n",xaxs="i",
  ylab=alab,yaxt="n",yaxs="i",
  type=type,col=col,cex=cex,xlim=qlim,...)
  if (!is.null(qlim)) E<-qlim[2] else E<-N/f
  X<-seq(0,E,length.out=7)
  axis(side=1,at=X, labels=round(X,3))
  axis(side=3,at=X, labels=round(1/X,3))

	if(!is.null(tpeaks))
    {
    text(seq(z)[p]/f, z[p]+abs((max(z)-min(z))/30),
      as.character(round((seq(z)[p]-1)/f,5)),col=colpeaks,cex=cexpeaks,font=fontpeaks)
    }

	if(!is.null(fpeaks))
    {
    text(seq(z)[p]/f, z[p]+abs((max(z)-min(z))/30),
      as.character(round(f/(seq(z)[p]-1),1)),col=colpeaks,cex=cexpeaks,font=fontpeaks)
    }

  if(tidentify == TRUE)
    {
    cat("time identification: choose points on the cepstrum\n")
    if (.Platform$OS.type == "windows") flush.console()
    id<-identify(x=x,y=z,labels=round(x,5),tolerance=0.15,col="red")
    return(round(x[id],5))
    }
    
  if(fidentify == TRUE)
    {
    cat("frequency identification: choose points on the cepstrum\n")
    if (.Platform$OS.type == "windows") flush.console()
    id<-identify(x=x,y=z,labels=round(1/round(x,5),1),tolerance=0.15,col="red")
    return(round(1/round(x[id],5),1))
    }
  }

else
 {
  if(!is.null(tpeaks) | !is.null(fpeaks))
   {
   results<-list(ceps=c(x,z) ,peaks=respeaks)
   return(results)
   }
  return(cbind(x,z))
 }
}


################################################################################
##                                   CEPSTRO                                    
################################################################################

cepstro<-function(
wave,
f,
wl = 512,
ovlp = 0,
plot = TRUE,
grid = TRUE,
scale = TRUE,
cont = FALSE,
collevels = seq(0,1,0.01),
palette = rev.heat.colors,
contlevels = seq (0,1,0.01),
colcont = "black",
colbg = "white",
colgrid = "black",
colaxis = "black",
collab = "black",
plot.title =
    title(main = "", xlab = "Time (s)",
    ylab = "Quefrency (kHz)"),
scalelab = "Amplitude",
scalefontlab = 1,
scalecexlab =0.75,
axisX = TRUE,
axisY = TRUE,
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)
wave<-ifelse(wave==0,yes=1e-6,no=wave)

n<-nrow(wave)
p<-round(n/2)
step<-seq(1,n-wl,wl-(ovlp*wl/100))

N<-length(step)
WL<-wl%/%2
z1<-matrix(data=numeric(wl*N),wl,N)
for(i in step)
  {z1[,which(step==i)]<-Re(fft(log(abs(fft(wave[i:(wl+i-1),]))),inverse=TRUE))}
z2<-z1[1:WL,]
z<-ifelse(z2=="NaN"|z2=="-Inf"|z2<=0,yes=0,no=z2)
Z<-t(z/max(z))

if (plot == TRUE)
 	{
  X<-seq(0,n/f,length.out=length(step))
  Y<-seq(0,WL/f,length.out=nrow(z))*1000
  Zlim<-range(Z, finite = TRUE)
  if (scale==TRUE)
    {
    def.par <- par(no.readonly = TRUE)
    on.exit(par(def.par))
    layout(matrix(c(1, 2), nc = 2, byrow=TRUE), widths = c(6, 1))
    par(mar=c(5,4.1,1,0),las=1,cex=1,col=colaxis,col.axis=colaxis,col.lab=collab,bg=colbg)
    filled.contour.modif2(x=X ,y=Y, z=Z, levels=collevels, nlevels=20,
			plot.title=plot.title, color.palette=palette,axisX=axisX, axisY=FALSE)
		tck<-seq(0,WL/f,length.out=7)*1000
		if(axisY==TRUE) axis(side=2, at=tck, labels=round(1/tck,3),col.axis=colaxis,col.lab=collab)
   	if(grid == TRUE) grid(nx=NA, ny=NULL, col=colgrid)
		if(colaxis != colgrid) abline(h=0,col=colaxis) else abline(h=0,col=colgrid)
    par(mar=c(5,1,4.5,3),las=0)
    dBscale(collevels=collevels,palette=palette,fontlab=scalefontlab,
      cexlab=scalecexlab,collab=collab,textlab=scalelab,colaxis=colaxis)
    }

  if (scale==FALSE)
   {
   par(las=1, col=colaxis, col.axis=colaxis, col.lab=collab,bg=colbg,...)
   filled.contour.modif2(x=X ,y=Y, z=Z, levels=collevels, nlevels=20,
			plot.title=plot.title, color.palette=palette, axisX=axisX, axisY=axisY,
      col.lab=collab,colaxis=colaxis)
   if (grid == TRUE) grid(nx=NA, ny=NULL, col=colgrid)
 	 if(colaxis != colgrid) abline(h=0,col=colaxis) else abline(h=0,col=colgrid)
	 }

  if (cont==TRUE)
	 {
   contour(X,Y,Z,add=TRUE,
	 levels=contlevels,nlevels=5,col=colcont,...)
	 }
  }

else{return(Z)}
}



################################################################################
##                                COH                                         
###############################################################################

coh<-function(
wave1,
wave2,
f,
plot =TRUE,
xlab = "Frequency (kHz)",
ylab = "Coherence",
xlim = c(0,f/2000),
type = "l",
...
)

{
input1<-inputw(wave=wave1,f=f) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
wave2<-inputw(wave=wave2,f=f)$w

n1<-nrow(wave1)
n2<-nrow(wave2)
if (n1 != n2) stop("'wave 1' and 'wave 2' must have the same length")

Y<-spec.pgram(cbind(wave1, wave2), fast=FALSE, taper=FALSE,
    spans = c(3,3),plot=FALSE)$coh
X<-seq(0,f/2000,length.out=nrow(Y))

if (plot == TRUE)
  {
  plot(x=X,y=Y,xlab=xlab,ylab=ylab,xlim=xlim,type=type,...)
  }
else return(cbind(X,Y))
}



################################################################################
##                                CONVSPL                                         
###############################################################################

convSPL<-function
(
x,
d = 1,
Iref = 10^-12,
pref = 2*10^-5 
)

{
P<-4*pi*(d^2)*Iref*(10^(x/10))
I<-Iref*(10^(x/10))
p<-pref*(10^(x/20))
conv<-list(P = P, I = I, p = p)
return(conv)
}


################################################################################
##                                CORENV                                         
################################################################################

corenv<-function(
wave1,
wave2,
f,
envt="hil",
msmooth = NULL,
ksmooth = NULL,
plot = TRUE,
plotval = TRUE,
method = "spearman",
col = "black",
colval = "red",
cexval = 1,
fontval = 1,
xlab = "Time (s)",
ylab = "Coefficient of correlation (r)",
type= "l",
...)

{
input1<-inputw(wave=wave1,f=f) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
wave2<-inputw(wave=wave2,f=f)$w

n<-nrow(wave1)

cat("please wait...")
if(.Platform$OS.type == "windows") flush.console()
  
x<-env(wave=wave1,f=f,envt=envt,msmooth=msmooth,ksmooth=ksmooth,plot=FALSE)
y<-env(wave=wave2,f=f,envt=envt,msmooth=msmooth,ksmooth=ksmooth,plot=FALSE)

nx<-nrow(x)
ny<-nrow(y)

if (nx != ny) stop("'wave 1' and 'wave 2' must have the same length")

meanx<-mean(x)
meany<-mean(y)
diffx<-x-meanx
r1<-numeric(nx)
r2<-numeric(nx)

for (i in 0:(nx-1)){r1[i+1]<-cor(x=x,y=c(y[(i+1):ny],rep(0,i)),method = method)}
for (i in 0:(nx-1)){r2[i+1]<-cor(x=x,y=c(rep(0,i),y[1:(ny-i)]),method = method)}

r2<-r2[-1]
r<-c(rev(r1),r2)
rmax<-max(r,na.rm=TRUE)
offset<-which.max(r)
if(offset<=(length(r)/2)) {offsetp<-which.max(r)} else {offsetp<-which.max(r)-1}
if(!is.null(msmooth)|!is.null(ksmooth)) {F<-f*nx/n; offsett<-(offsetp-nx)/F}
else{offsett<-(offsetp-n)/f}

if (offsetp < nx){p<-cor.test(x=x, y=c(y[(nx-offsetp+1):ny],rep(0,nx-offsetp)),method = method)}
else {p<-cor.test(x=x, y=c(rep(0,offsetp-nx),y[1:(ny-(offsetp-nx))]), method = method)}
p<-p$p.value

X<-seq(-n/f,n/f,length.out=2*nx-1)
  
if (plot == TRUE)
  {
  plot(x = X, y = r, xlab = xlab, ylab = ylab, col = col, type = type,...)
  if (plotval==TRUE)
    {
    mtext(paste(
      "rmax = ", as.character(round(rmax,2)),
      ", offset = ", as.character(round(offsett,3)), "s", sep=" "),
      side=3, line=-2, col=colval, cex=cexval, font=fontval)
    segments(x0=round(offsett,3),y0=min(r), x1=round(offsett,3), y1=rmax, col=colval, lty=2)
    segments(x0=-n/f,y0=rmax, x1=round(offsett,3), y1=rmax, col=colval, lty=2)
    points(x=round(offsett,3),y=rmax,pch=19,cex=1, col=colval)
  }
  }

else
  {
  corr<-list(r = cbind(X,r), rmax = rmax, p = p, t = offsett)
  return(corr)
  }

}



################################################################################
##                                CORSPEC                                         
################################################################################

corspec<-function(
spec1,
spec2,
f = NULL,
plot = TRUE,
plotval = TRUE,
method = "spearman",
col = "black",
colval = "red",
cexval = 1,
fontval = 1,
xlab = "Frequency (kHz)",
ylab = "Coefficient of correlation (r)",
type ="l",
...)

{
if(is.null(f)==TRUE)
  {
  if(is.vector(spec1)==TRUE & is.vector(spec2)==TRUE) stop("'f' is missing")  
  else
    {
    if(is.matrix(spec1)==TRUE) f<-spec1[nrow(spec1),1]*2000
    else if(is.matrix(spec2)==TRUE) f<-spec2[nrow(spec2),1]*2000
    }
  }

range<-c(0,f/2000)

if(is.matrix(spec1)==TRUE && ncol(spec1)==2) spec1<-spec1[,2]
if(is.matrix(spec2)==TRUE && ncol(spec2)==2) spec2<-spec2[,2]

n1<-length(spec1)
n2<-length(spec2)

if (n1 != n2) stop("'spec1' and 'spec2' must have the same length")
if(any(spec1 < 0) | any(spec2 < 0)) stop("data does not have to be in dB")

mean1<-mean(spec1)
mean2<-mean(spec2)
diffx<-spec1-mean1
r1<-numeric(n1)
r2<-numeric(n2)

for (i in 0:(n1-1))
{
r1[i]<-cor(x=spec1,y=c(spec2[(i+1):n2],rep(0,i)),method = method)
}

for (i in 0:(n1-1))
{
r2[i+1]<-cor(x=spec1,y=c(rep(0,i),spec2[1:(n2-i)]),method = method)
}

r2<-r2[-1]
r<-c(rev(r1),r2)

rmax<-max(r,na.rm=TRUE)
offset<-which.max(r)
if (offset<=(length(r)/2)) {offsetp<-which.max(r)} else {offsetp<-which.max(r)-1}
offsetf<-((range[2]-range[1])*(offsetp-n1))/n1

if (offsetp < n1)
      {
      p<-cor.test(x=spec1, y=c(spec2[(n1-offsetp+1):n2],rep(0,n1-offsetp)),
      method = method)
      }
else
      {
      p<-cor.test(x=spec1, y=c(rep(0,offsetp-n1),spec2[1:(n2-(offsetp-n1))]),
      method = method)
      }
p<-p$p.value    

X<-seq(-range[2],range[2],length.out=2*n1-1)

if (plot == TRUE)
  {
  plot(x = X, y = r, xlab = xlab, ylab = ylab, col = col, type = type,...)
  if (plotval==TRUE)
    {
    mtext(paste(
      "rmax = ", as.character(round(rmax,2)),
      ", offset = ", as.character(round(offsetf,2)), "kHz", sep=" "),
      side=3, line=-2, col=colval, cex=cexval, font=fontval)
    segments(x0=offsetf,y0=min(r), x1=offsetf, y1=rmax, col=colval, lty=2)
    segments(x0=-range[2],y0=rmax, x1=offsetf, y1=rmax, col=colval, lty=2)
    points(x=offsetf,y=rmax,pch=19,cex=1, col=colval)
  }
  }
  
else  
  {
  corr<-list(r = cbind(X,r), rmax = rmax, p = p, f = offsetf)
  return(corr)
  }

}



################################################################################
##                                COVSPECTRO                                         
################################################################################


covspectro<-function
(
wave1,
wave2,
f,
wl = 512,
wn = "hanning",
n,
plot = TRUE,
plotval = TRUE,
method = "spearman",
col = "black",
colval = "red",
cexval = 1,
fontval = 1,
xlab = "Time (s)",
ylab = "Normalised covariance (cov)",
type ="l",
...
)

{
input1<-inputw(wave=wave1,f=f) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
wave2<-inputw(wave=wave2,f=f)$w

if (n>21)
  {
  cat("please wait...")
  if (.Platform$OS.type == "windows") flush.console()
  }
  
if((n <- as.integer(n)) %% 2 != 1) stop("'n' must be odd")

n<-(n%/%2)+1

n1<-nrow(wave1)
n2<-nrow(wave2)

if (n1 != n2) stop("'wave 1' and 'wave 2' must have the same length")

step1<-seq(1,n1-wl,wl); lstep1<-length(step1)
step2<-round(seq(1,n2,length.out=n))

# wave not time shifted
spectro1<-sspectro(wave=wave1,f=f,wl=wl,wn=wn)
WL<-wl%/%2
spectro2a<-array(numeric(WL*lstep1*n),dim=c(WL,lstep1,n))
spectro2b<-array(numeric(WL*lstep1*n),dim=c(WL,lstep1,n))
cov1<-numeric(n)
cov2<-numeric(n)

# wave time shifted
# successive spectrograms
# covariance of spectrogram1/spectra1 with spectrogram2/spectra1,
# spectrogram1/spectra2 with spectrogram2/spectra2 and so on
# diagonal of the cov matrix and mean of this diagonal
# one mean cov for comparaison between 2 spectrograms for(i in step2)
for (i in step2)
{
spectro2a[,,which(step2==i)]<-sspectro(wave=as.matrix(c(wave2[i:n2],rep(0,i-1))),f=f,wl=wl,wn=wn)
spectro2a<-ifelse(spectro2a=="NaN",yes=0,no=spectro2a)
cov1[which(step2==i)]<-mean(diag(cov(x=spectro1,y=spectro2a[,,which(step2==i)],method = method)))
}

for (i in step2)
{
spectro2b[,,which(step2==i)]<-sspectro(wave=as.matrix(c(rep(0,i),wave2[1:(n2-i)])),f=f,wl=wl,wn=wn)
spectro2b<-ifelse(spectro2b=="NaN",yes=0,no=spectro2b)
cov2[which(step2==i)]<-mean(diag(cov(x=spectro1,y=spectro2b[,,which(step2==i)],method = method)))
}

# to normalise the covariance we need covmax that is the autocovariance of spectro1
covmax<-mean(diag(cov(x=spectro1,y=spectro1,method = method)))

# discard the first value of cov2 that is already computed in cov1
cov2<-cov2[-1]
cov3<-c(rev(cov1),cov2)
cov4<-cov3/covmax
cov4max<-max(cov4)
offset<-which.max(cov4)
offsetp<-which.max(cov4)
offsett<-(((offsetp*n1)/n)-n1)/f

if (plot == TRUE)
  {
  x<-seq(-n1/f,n1/f,length.out=(2*n)-1)
  plot(x = x, y = cov4, xlab = xlab, ylab = ylab, col = col, type = type,...)
  if (plotval == TRUE)
    {
    mtext(paste(
      "covmax = ", as.character(round(cov4max,2)),
      ", offset = ", as.character(round(offsett,3)), "s", sep=" "),
      side=3, line=-2, col=colval, cex=cexval, font=fontval)
    segments(x0=round(offsett,3),y0=min(cov4), x1=round(offsett,3), y1=cov4max, col=colval, lty=2)
    segments(x0=-n1/f,y0=cov4max, x1=round(offsett,3), y1=cov4max, col=colval, lty=2)
    points(x=round(offsett,3),y=cov4max,pch=19,cex=1, col=colval)
    }
  }

else
  {
  covar<-list(cov = cov4, covmax = cov4max, t = offsett)
  return(covar)
  }

}


################################################################################
##                                CSH
################################################################################


csh<-function(
wave,
f,
wl = 512,
wn = "hanning",
ovlp = 0,
threshold = NULL,
plot = TRUE,
xlab = "Times (s)",
ylab = "Spectral Entropy",
ylim = c(0,1.1),
type = "l",
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

# threshold
if(!is.null(threshold)) wave<-afilter(wave=wave,f=f,threshold=threshold,plot=FALSE)

# STFT (see function spectro())
n<-nrow(wave)
step<-seq(1,n-wl,wl-(ovlp*wl/100))
z1<-matrix(data=numeric(wl*length(step)),wl,length(step))
W<-ftwindow(wl=wl,wn=wn)
for(i in step) {z1[,which(step==i)]<-Mod(fft(wave[i:(wl+i-1),]*W))}
z2<-z1[1:(wl/2),]
z3<-z2/max(z2)

# sh applied to the Fourier matrix
z4<-apply(z3,MARGIN=2,FUN=sh)

x<-seq(0,n/f,length.out=length(step))

# graphic
if (plot==TRUE)
  {
	plot(x=x, y=z4,
	xaxs = "i", xlab = xlab,
  yaxs = "i", ylab = ylab, ylim = ylim,
  type = type,
  ...)
	}
else
return(cbind(c,z4))
}


################################################################################
##                                CUTSPEC                                       
################################################################################

cutspec<-function(
spec,
f=NULL,
flim,
norm=FALSE,
PMF=FALSE
)

{
if(norm==TRUE & PMF==TRUE) stop("'norm' and 'PMF' should not be both set to TRUE")

if(is.vector(spec))
	{
	if(is.null(f)) stop("'f' is missing and is necessary when 'spec' is a vector")  
	wl<-length(spec)*2
	specut<-spec[(flim[1]*1000*wl/f):(flim[2]*1000*wl/f)]
	if(norm==TRUE) {specut<-specut/max(specut)}
	if(PMF==TRUE)  {specut<-specut/sum(specut)}	
	}

else if(is.matrix(spec))
	{
	if(ncol(spec)>2){stop("'spec' should not have more than two columns")}
	if(is.null(f)==TRUE) {f<-spec[nrow(spec),1]*2000}
	wl<-nrow(spec)*2
	specut<-spec[(flim[1]*1000*wl/f):(flim[2]*1000*wl/f), ,drop=FALSE]
	if(norm==TRUE) {specut[,2]<-specut[,2]/max(specut[,2])}
	if(PMF==TRUE)  {specut[,2]<-specut[,2]/sum(specut[,2])}
	}

return(specut)
}


################################################################################
##                                CUTW                                         
################################################################################

cutw<-function(
wave,
f,
from = NULL,
to = NULL,
choose = FALSE,
plot = FALSE,
marks = TRUE,
Sample = FALSE,
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(choose==TRUE)
  { 
	cat("choose start and end positions on the wave\n")
  if (.Platform$OS.type == "windows") flush.console()
  oscillo(wave,f=f)
	coord<-locator(n=2)
  from<-coord$x[1]; a<-round(from*f) ; abline(v=from,col=2,lty=2)
  to<-coord$x[2]; b<-round(to*f); abline(v=to,col=2,lty=2)
	}
else if(!is.null(from)|!is.null(to))
  {
  if(is.null(from) && !is.null(to)) {a<-1; b<-round(to*f)}
  if(!is.null(from) && is.null(to)) {a<-round(from*f); b<-length(wave)}
	if(!is.null(from) && !is.null(to))
		{
		if (from>to) stop("'from' cannot be superior to 'to'")
		if(from==0) {a<-1} else a<-round(from*f)
		b<-round(to*f)
		}
  }

wavecut1<-as.matrix(wave[a:b,])
wavecut<-wavecut1/max(abs(wavecut1))
  
if (plot == TRUE)
  {
  def.par <- par(no.readonly = TRUE)
  on.exit(par(def.par))
  par(mfrow=c(2,1),oma=c(0,0.1,0,0))
  oscillo(wave,f=f,...)
  title(main="original")
    if (marks == TRUE)
      {
      abline(v=from, col="red", lty=2)
      abline(v=to, col="red", lty=2)
      }
  oscillo(wavecut,f=f,...)
  title(main="cut")
  }
else 
    {
    if (Sample == TRUE){wavecut<-as.Sample(as.numeric(wavecut), rate=f, bits=16)}
    return(wavecut)
    }
}

 
################################################################################
##                                DBSCALE                                        
################################################################################

dBscale<-function
(
collevels,
palette = spectro.colors,
side = 4,
textlab = "Amplitude\n(dB)",
cexlab = 0.75,
fontlab = 1,
collab = "black",
colaxis = "black",
...
)

{
plot.new()
levels<-collevels
col <- palette(length(collevels) - 1)
par(las=1)
    
if (side == 2 | side == 4)
    {    
    plot.window(xlim = c(0, 1), ylim = range(collevels), xaxs = "i",
        yaxs = "i")
    mtext(textlab, side=3, outer=FALSE, line=1.5, adj=0, font=fontlab, cex=cexlab, col=collab)
    rect(xleft=0, ybottom=levels[-length(levels)], xright=0.95, ytop=levels[-1],
      col = col, lty=0, border = TRUE)
    segments(x0=0,y0=max(collevels),x1=0.95,y1=max(collevels),col=colaxis)
    segments(x0=0,y0=min(collevels),x1=0.95,y1=min(collevels),col=colaxis)          
    abline(v=c(0,0.95),col=colaxis)
    if (side == 2) axis(2,col=colaxis,col.axis=colaxis,...)
    if (side == 4) axis(4,pos=0.95,col=colaxis,col.axis=colaxis,...)
    }

if (side == 1  | side == 3)
    {    
    plot.window(xlim = range(collevels), ylim = c(0, 1), xaxs = "i",
        yaxs = "i")
    mtext(textlab, side=3, outer=FALSE, line=1.5, adj=0, font=fontlab, cex=cexlab, col=collab)
    rect(xleft=levels[-length(levels)], ybottom=0, xright=levels[-1], ytop=0.95, col = col, lty=0)
    segments(x0=min(collevels),y0=0,x1=min(collevels),y1=0.95,col=colaxis)
    segments(x0=max(collevels),y0=0,x1=max(collevels),y1=0.95,col=colaxis)       
    abline(h=c(0,0.95),col=colaxis)
    if (side == 1) axis(1,col=colaxis,col.axis=colaxis,...)
    if (side == 3) axis(3,pos=0.95,col=colaxis,col.axis=colaxis,...)
    }    
}    


################################################################################
##                                DELETEW
################################################################################

deletew<-function(
wave,
f,
from = NULL,
to = NULL,
choose = FALSE,
plot = FALSE,
marks = TRUE,
Sample = FALSE,
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(choose==TRUE)
  { 
	cat("choose start and end positions on the wave\n")
  if (.Platform$OS.type == "windows") flush.console()
  oscillo(wave,f=f)
	coord<-locator(n=2)
  from<-coord$x[1]; a<-round(from*f) ; abline(v=from,col=2,lty=2)
  to<-coord$x[2]; b<-round(to*f); abline(v=to,col=2,lty=2)
	}
else if(!is.null(from)|!is.null(to))
  {
  if(is.null(from) && !is.null(to)) {a<-1; b<-round(to*f)}
  if(!is.null(from) && is.null(to)) {a<-round(from*f); b<-length(wave)}
	if(!is.null(from) && !is.null(to))
		{
		if (from>to) stop("'from' cannot be superior to 'to'")
		if(from==0) {a<-1} else a<-round(from*f)
		b<-round(to*f)
		}
  }
wavecut<-as.matrix(wave[-(a:b),])

if (plot == TRUE)
  {
  def.par <- par(no.readonly = TRUE)
  on.exit(par(def.par))
  par(mfrow=c(2,1))
  oscillo(wave,f=f,k=1,j=1,...)
  title(main="original")
    if (marks == TRUE)
      {
      abline(v=from, col="red", lty=2)
      abline(v=to, col="red", lty=2)
      }
  oscillo(wavecut,f=f,k=1,j=1,...)
  title(main="after deletion")
  }
else 
    {
    if (Sample == TRUE){wavecut<-as.Sample(as.numeric(wavecut), rate=f, bits=16)}
    return(wavecut)
    }
}


################################################################################
##                                DFREQ                                         
################################################################################

dfreq<-function(
wave,
f,
wl = 512,
wn = "hanning",
ovlp = 0,
threshold = NULL,
plot = TRUE,
xlab = "Times (s)",
ylab = "Frequency (kHz)",
ylim = c(0,f/2000),
type ="l",
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(!is.null(threshold)) {wave<-afilter(wave=wave,f=f,threshold=threshold,plot=FALSE)}
wave<-ifelse(wave==0,yes=1e-6,no=wave)

n<-nrow(wave)
step<-seq(1,n-wl,wl-(ovlp*wl/100))
N<-length(step)
y1<-matrix(data=numeric(wl*N),wl,N)
W<-ftwindow(wl=wl,wn=wn)
for(i in step)
{y1[,which(step==i)]<-Mod(fft(wave[i:(wl+i-1),]*W))}
		
y2<-y1[1:(wl/2),]				

y3<-matrix(data=numeric(N*2),N,2)
for (i in 1:N)
# [1,1] is to keep only the first line and firt column of the results (=c(1,1))
# when there is no max value, this happens when the fft is totatally flat
# (e. g. signal =0)
{y3[i,]<-as.numeric(which(y2==max(y2[,i]),arr.ind=TRUE)[1,1])}
y3<-(f*y3[,1])/(1000*wl)
# discards max results when signal = 0, i. e. when which.max = c(1,1)
y<-ifelse(y3==f/(wl*1000), yes=NA, no=y3)

x<-seq(0,n/f,length.out=N)

if (plot==TRUE)
  {
	plot(x=x, y=y,
	xaxs="i", xlab = xlab,
	yaxs="i", ylab = ylab, ylim = ylim,
  type = type,
  ...)
	}
else
return(cbind(x,y))
}


################################################################################
##                                DIFFENV                                        
################################################################################

diffenv<-function(
wave1,
wave2,
f,
envt = "hil",
msmooth = NULL,
ksmooth = NULL,
plot = FALSE,
lty1 = 1,
lty2 = 2,
col1 = 2,
col2 = 4,
cold = 8,
xlab = "Time (s)",
ylab = "Amplitude",
ylim = NULL,
legend = TRUE,
...
)

{
leg<-c(as.character(deparse(substitute(wave1))),as.character(deparse(substitute(wave2))))

input1<-inputw(wave=wave1,f=f) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
wave2<-inputw(wave=wave2,f=f)$w

env1<-env(wave=wave1,f=f,envt=envt,msmooth=msmooth,ksmooth=ksmooth,plot=FALSE)
env2<-env(wave=wave2,f=f,envt=envt,msmooth=msmooth,ksmooth=ksmooth,plot=FALSE)

n1<-length(env1)
n2<-length(env2)
if (n1 != n2) stop("wave1 and wave2 should have the same length")

if(!is.null(msmooth)|!is.null(ksmooth)) {f<-f*n1/nrow(wave1)}

envPMF1<-env1/sum(env1)
envPMF2<-env2/sum(env2)

denv<-sum(abs(envPMF1-envPMF2))/2

if (plot==TRUE)
  {
  x<-seq(0,n1/f,length.out=n1)
  if (is.null(ylim)) ylim<-c(0,max(envPMF1,envPMF2))
  plot(x=x, y=envPMF1, type="n",
    xaxs="i",
    ylim=ylim, yaxs="i",
    axes=FALSE, ann=FALSE, ...)
  par(new=TRUE)
  plot(x=x, y=envPMF2, type="n",
    xaxs="i",
    ylim=ylim, yaxs="i",
    axes=FALSE, ann=FALSE, ...)
  polygon(x=c(x,rev(x)),
    y=c(envPMF1,rev(envPMF2)),
    col=cold,
    border=NA)
  par(new=TRUE)
  plot(x=x, y=envPMF1, type="l", lty=lty1, col=col1,
      xaxs="i", xlab=xlab,
      yaxs="i", yaxt="n", ylim=ylim, ylab=ylab,...)
  par(new=TRUE)
  plot(x=x, y=envPMF2, type="l", lty=lty2, col=col2,
      xaxs="i", xlab="",
      yaxs="i", yaxt="n", ylim=ylim, ylab="",...)
  if(legend==TRUE) {legend("topleft", col=c(col1,col2),lty=c(lty1,lty2),legend=leg)}
  }
  
return(denv)
}


################################################################################
##                                DIFFSPEC                                         
################################################################################

diffspec<-function(
spec1,
spec2,
f = NULL,
dB = FALSE,
plot = FALSE,
type = "l",
lty1 = 1,
lty2 = 2,
col1 = 2,
col2 = 4,
cold = 8,
flab = "Frequency (kHz)",
alab = "Amplitude",
flim = NULL,
alim = NULL,
legend = TRUE,
...
)

{
leg<-c(as.character(deparse(substitute(spec1))),as.character(deparse(substitute(spec2))))

if(is.null(f)==TRUE)
  {
  if(is.vector(spec1)==TRUE & is.vector(spec2)==TRUE) stop("'f' is missing")  
  else
    {
    if(is.matrix(spec1)==TRUE) f<-spec1[nrow(spec1),1]*2000
    else if(is.matrix(spec2)==TRUE) f<-spec2[nrow(spec2),1]*2000
    }
  }

if(is.matrix(spec1)==TRUE && ncol(spec1)==2) spec1<-spec1[,2]
if(is.matrix(spec2)==TRUE && ncol(spec2)==2) spec2<-spec2[,2]

n1<-length(spec1)
n2<-length(spec2)

if (n1 != n2) stop("spec1 and spec2 must have the same length")
if (any(spec1 < 0) | any(spec2 < 0))
  stop("spectra (spec 1 and/or spec 2) do not have to be in dB")

spec1<-spec1/sum(spec1)
spec2<-spec2/sum(spec2)

dspec<-sum(abs(spec1-spec2))/2

if (dB == TRUE)
  {
  dspec<-20*log10(dspec)
  spec1<-20*log10(spec1)
  spec2<-20*log10(spec2)
  }

if (plot==TRUE)
  {
  x<-seq((f/2000)/n1,f/2000,length.out=n1)
  st<-(f/2000)/n1
  en<- f/2000
  if(is.null(alim)) alim<-c(0,max(spec1,spec2))
  if(is.null(flim)) flim<-c(0,f/2000)
  plot(x=x, y=spec1, type="n",
    xlim=flim, xaxs="i",
    ylim=alim, yaxs="i",
    axes=FALSE, ann=FALSE)
  par(new=TRUE)
  plot(x=x, y=spec2, type="n",
    xlim=flim, xaxs="i",
    ylim=alim, yaxs="i",
    axes=FALSE, ann=FALSE)
  polygon(x=c(seq(st,en,length.out=n1),seq(en,st,length.out=n1)),
    y=c(spec1,rev(spec2)),
    col=cold,
    border=NA)
  par(new=TRUE)
  plot(x=x, y=spec1, type=type, lty=lty1, col=col1,
      xaxs="i", xlab=flab, xlim=flim,
      yaxs="i", ylim=alim, ylab=alab,...)
  par(new=TRUE)
  plot(x=x, y=spec2, type=type, lty=lty2, col=col2,
      xaxs="i", xlab="", xlim=flim,
      yaxs="i", ylim=alim, ylab="",...)
  if(legend==TRUE) legend("topleft", col=c(col1,col2),lty=c(lty1,lty2),legend=leg)
  }
return(dspec)
}


################################################################################
##                               DIFFWAVE                                        
################################################################################

diffwave<-function(
wave1,
wave2,
f,
wl = 512,
envt= "hil",
msmooth = NULL,
ksmooth = NULL
)

{
input1<-inputw(wave=wave1,f=f) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
wave2<-inputw(wave=wave2,f=f)$w

# spectral difference
spec1<-meanspec(wave=wave1,f=f,wl=wl,PMF=TRUE,plot=FALSE)
spec2<-meanspec(wave=wave2,f=f,wl=wl,PMF=TRUE,plot=FALSE)
DF<-diffspec(spec1=spec1,spec2=spec2,f=f,plot=FALSE)

# temporal difference 
DE<-diffenv(wave1=wave1,wave2=wave2,f=f,msmooth=msmooth,ksmooth=ksmooth,plot=FALSE)

z<-DF*DE
return(z)
}


################################################################################
##                               DISCRETS                                        
################################################################################

discrets<-function(
x,
symb=5,
collapse=TRUE
)

{
if(symb!=3 && symb!=5) stop("'symb' should be set to 3 or 5")
x<-inputw(wave = x,f = NULL)$w
n<-length(x)

if(symb==5)
	{
	# from the second point to the n-1 point
	s<-character(n-2)
	for (i in 1:(n-2))
		{
		if(x[i]<=x[i+1]   & x[i+1]<x[i+2])  s[i+1]<-"I"  # increase
		if(x[i]<=x[i+2]   & x[i+2]<=x[i+1]) s[i+1]<-"P"  # peak
		if(x[i+1]<x[i]    & x[i]<=x[i+2])   s[i+1]<-"T"  # trough
		if(x[i+1]<x[i+2]  & x[i+2]<=x[i])   s[i+1]<-"T"  # trough
		if(x[i+2]<x[i]    & x[i]<=x[i+1])   s[i+1]<-"P"  # peak
		if(x[i+2]<=x[i+1] & x[i+1]<x[i])    s[i+1]<-"D"  # decrease
		if(x[i]==x[i+1]   & x[i+1]==x[i+2]) s[i+1]<-"F"  # flat
		}
	}
else if(symb==3)
	{
	s<-character(n-1)
	# from the second point to the n point
	for(i in 1:(n-1))
		{
		if(x[i]==x[i+1]) s[i+1]<-"F"
		if(x[i]<x[i+1])  s[i+1]<-"I"
		if(x[i]>x[i+1])  s[i+1]<-"D"
		}
	}
s<-s[-1]
if(collapse==TRUE) s<-paste(s,collapse="")
return(s)  # length(s) = n-1 if symbols=3, length(s)=n-2 if symbols=5
}


################################################################################
##                                DRAWENV
################################################################################

drawenv<-function(
wave,
f,
n=20,
plot=FALSE,
listen = FALSE,
Sample = FALSE
)

{
# input
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

wave<-wave/max(abs(wave))
wave<-rmoffset(wave)

# interactive graph
oscillo(wave=wave,f=f)
cat("choose points on the positive amplitude side of the wave\nto change the amplitude profile (amplitude envelope)\n")
if (.Platform$OS.type == "windows") flush.console()
coord<-locator(n=n,type="p",col=2)

# coordinates ; ordered following x if positions are not localised in order along the x-time axis
X<-coord$x ; x<-round(X[order(X)]*f)
Y<-coord$y ; y<-Y[order(X)]
if(any(X<0)) stop("point localization cannot be on the negative part of the time axis")
if(any(X>(nrow(wave)/f))) stop("point localization cannot be outside the positive part of the time axis")
if(any(Y<0)) stop("point localization cannot be on the negative part of the amplitude axis")

# profile generation
profile<-numeric(nrow(wave))
profile[1:x[1]]<-seq(0,y[1],length.out=x[1])
for(i in 1:(length(x)-1))
	{
	profile[x[i]:x[i+1]]<-seq(y[i],y[i+1],length.out=x[i+1]-x[i]+1)
	}
profile[x[length(x)]:length(profile)]<-seq(y[length(x)],0,length.out=length(profile)-x[length(x)]+1)

# new wave generation
wave2<-rmam(wave,f=f)
wave2<-wave2/max(abs(wave2))
wave3<-wave2[,1]*profile

# output
if(plot==TRUE)
    {
    x11()
		oscillo(wave3,f=f)
    if(listen == TRUE) {listen(wave3,f=f)}
    }
else
    {
    if (Sample == TRUE){wave2<-as.Sample(as.numeric(wave3), rate=f, bits=16)}
    if(listen == TRUE) {listen(wave3,f=f)}
    return(wave3)
    }
}


################################################################################
##                               DYNSPEC                                        
################################################################################

dynspec<-function(
wave,
f,
wl = 512,
wn = "hanning",
zp = 0,
ovlp = 0,
norm = FALSE,
dB = FALSE,
plot = TRUE,
title = TRUE,
osc = FALSE,
flab = "Frequency (kHz)",
alab = "Amplitude",
alim = NULL,
flim = c(0,f/2000),
type ="l",
from = NULL,
to = NULL,
envt = NULL,
msmooth = NULL,
ksmooth = NULL,
colspec = "black",
coltitle = "black",
colbg = "white",
colline = "black",
colaxis = "black",
collab = "black",
cexlab = 1,
fontlab = 1,
colwave = "black",
coly0 = "lightgrey",
colcursor = "red",
bty = "l"
)

{
require(rpanel)
require(tcltk)

input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(!is.null(from)|!is.null(to))
  {
  if(is.null(from) && !is.null(to)) {a<-1; b<-round(to*f)}
  if(!is.null(from) && is.null(to)) {a<-round(from*f); b<-length(wave)}
	if(!is.null(from) && !is.null(to))
		{
		if (from > to) stop("'from' cannot be superior to 'to'")
		if(from==0) {a<-1} else a<-round(from*f)
		b<-round(to*f)
		}
	wave<-as.matrix(wave[a:b,])
  }

n<-nrow(wave)
step<-seq(1,n-wl,wl-(ovlp*wl/100))
lstep<-length(step)

# STFT
z1<-matrix(data=numeric((wl+(zp))*lstep),wl+zp,lstep)
zpl<-zp%/%2
if(zpl==0)
  {
  W<-ftwindow(wl=wl,wn=wn)
  for(i in step)
  {z1[,which(step==i)]<-Mod(fft(wave[i:(wl+i-1),]*W))}
  }
else
  {
  W<-ftwindow(wl=wl+zp,wn=wn)
  for(i in step)
  {z1[,which(step==i)]<-
  Mod(fft(c(1:zpl,wave[i:(wl+i-1),],1:zpl)*W))}
  }

z2<-z1[1:((wl+zp)/2),]

if (norm == TRUE)
  {
  z<-matrix(numeric(length(z2))); dim(z)<-dim(z2)
  for(i in 1:ncol(z)) {z[,i]<-z2[,i]/max(z2[,i])}
  }
else z<-z2/max(z2)

if (dB == TRUE)
  {
  z<-ifelse(z==0,yes=1e-6,no=z)
  z<-20*log10(z)[,]
  }

if(plot == TRUE)
  {
  if (is.null(alim) == TRUE)
  {
  alim<-c(0,max(z)+0.05)
  if(norm == TRUE && dB == FALSE) alim<-c(0,1.1)
  if(dB == TRUE) alim<-c(min(z),10)
  }
  
  x<-seq(f/1000/n,f/2000,length.out=nrow(z))
  pos<-1:lstep
  poslabel<-numeric(lstep)
  for (i in 1:lstep){poslabel[i]<-round((step[i]+((step[2]-step[1])/2))/f,3)}

  plot.spec<-function(panel)
  {
    with(panel,
    {
    par(bg=colbg, col=colline)
    if(osc==TRUE | !is.null(envt)) {layout(c(1,2),heights=c(2.5,1)); par(mar=c(4.5,4,3,2))}
    plot(x=x,y=z[,pos],
		  xaxs = "i", xlab = flab, xlim = flim,
		  yaxs = "i", yaxt = "s", ylab = alab, ylim = alim,
		  col = colspec, col.axis = colaxis,
      	  col.lab = collab, cex.lab = cexlab, font.lab = fontlab,
      	  type = type, las = 1)

  if(title==TRUE)
    title(main=paste(pos,"- Position along the signal =",poslabel[pos],"s",sep=" "),
    col.main=coltitle)
  if(title==FALSE) title(main="")
  if(is.character(title)) title(main = paste(title), col.main = coltitle)

  if(osc==TRUE)
    {
    par(mar=c(4.5,4,0.5,2))
    soscillo(wave = wave, f = f,
    colwave = colwave, collab = collab,
    cexlab = cexlab, fontlab = fontlab, colline = colline,
    colaxis = colaxis, coly0 = coly0, bty = bty,
	  tickup=max(abs(wave),na.rm=TRUE),
    ylim=c(-max(abs(wave)),max(abs(wave))))
    abline(v=poslabel[pos], col=colcursor)
    }
  else if(!is.null(envt))
    {
    par(mar=c(4.5,4,0.5,2))
    env(wave = wave, f = f, k=1, j=1,
    envt = envt, msmooth = msmooth, ksmooth = ksmooth,
    colwave = colwave, collab = collab,
    cexlab = cexlab, fontlab = fontlab, colline = colline,
    colaxis = colaxis, coly0 = coly0, bty = bty)
    abline(v=poslabel[pos], col=colcursor)
    }
  }
  )
  panel
  }

spec.panel <- rp.control("Position")
rp.slider(spec.panel, pos, from=1, to=lstep, resolution=1,
       title = "Position along the signal", action=plot.spec)
}
else return(z)
}


################################################################################
##                               ECHO
################################################################################

echo<-function(
wave,
f,
amp,
delay,
plot= FALSE,
listen = FALSE,
Sample = FALSE,
...
)

{
cat("Please wait...\n")
if (.Platform$OS.type == "windows") flush.console()

input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

wave<-wave/max(abs(wave))
n<-nrow(wave)
namp<-length(amp)
ndelay<-length(delay)
delayp<-delay*f
if(namp!=ndelay) stop("'namp' and 'ndelay' arguments should have the same length")
if(any(namp)>1)  stop("'namp' argument cannot be > 1")
if(any(namp)<0)  stop("'namp' argument cannot be negative")

pulse<-c(1,numeric(delayp[namp]+n-1))
for(i in 1:namp) pulse[delayp[i]]<-amp[i]
pulse<-rev(pulse)
wave2<-convolve(wave[,1],pulse,type="open")
# delete the zero padded at the end of the wave by convolve()
wave3<-wave2[1:(delayp[namp]+n)]
wave3<-as.matrix(wave3)

if(plot==TRUE)
    {
    oscillo(wave=wave3,f=f,...)
    if(listen == TRUE) {listen(wave3,f=f)}
    }
else
    {
    if(Sample == TRUE) {wave3<-as.Sample(as.numeric(wave3), rate=f, bits=16)}
    if(listen == TRUE) {listen(wave3,f=f)}
    return(wave3)
    }
}


################################################################################
##                               ENV                                        
################################################################################


env<-function
(
wave,
f,
envt = "hil",
msmooth = NULL,   
ksmooth = NULL,
norm = FALSE,	
plot = TRUE,
k=1,
j=1,
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)
n<-nrow(wave)

if(envt=="hil"){wave1<-Mod(hilbert(wave,f=f))}
if(envt=="abs"){wave1<-abs(wave)}

if(!is.null(msmooth))
	{
  if(msmooth[1] == 0) stop("'smooth' window length cannot be equal to 0")
  if(msmooth[1] == 1) stop("'smooth' window length cannot be equal to 1")
  if(msmooth[2] == 100) stop("'smooth' window overlap cannot be equal to 100")
  step<-seq(1,n-msmooth[1],msmooth[1]-(msmooth[2]*msmooth[1]/100))
  wave2<-numeric(length(step))
  for(i in step) {wave2[which(step==i)]<-mean(wave1[i:(i+msmooth[1])])}
  wave1<-as.matrix(wave2)
	f<-f*nrow(wave1)/n
	}

if(!is.null(ksmooth))
	{
	wave2<-kernapply(as.matrix(wave1),ksmooth)
  wave1<-as.matrix(wave2)
	f<-f*nrow(wave1)/n
  }

if(plot==TRUE) {oscillo(wave=wave1,f=f,k=k,j=j,...)}
else
	{
	if(norm==TRUE) wave1<-wave1/max(abs(wave1))
	return(as.matrix(wave1))
	}
}


################################################################################
##                               EXPORT
################################################################################

export<-function(
wave,
f,
filename = NULL,
header = TRUE, 
...)

{
if(is.null(filename) == TRUE) {filename <- paste(as.character(deparse(substitute(wave))),".txt",sep="")}

input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

wave<-wave/(max(abs(wave))*1.5) # this avoids overclipping problems
n<-nrow(wave)
if(header==TRUE) {header<-paste("[ASCII ",f,"Hz, Channels: 1, Samples: ",n,", Flags: 0]", sep="")}
else 
	{
	if(header==FALSE) header<-FALSE
	if(is.character(header)) header<-header
	}
write.table(x=wave, file=filename, row.names=FALSE, col.names=header, quote=FALSE, ...)
}


################################################################################
##                                FADEW
################################################################################

fadew<-function(
wave,
f,
din = 0,
dout = 0,
shape = "linear",
plot = FALSE,
listen = FALSE,
Sample = FALSE,
...
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

wave<-wave/max(abs(wave))
n<-nrow(wave)
ndin<-din*f
ndout<-dout*f
nfade<-ndin+ndout

if(din==0 && dout==0) stop("Please specify at least a fade in or a fade out duration.")
if(nfade>n) stop("The sum of fade in and fade out durations cannot be longer than wave length.")
if(ndin>n) stop("Fade in duration cannot be longer than wave length.")
if(ndout>n) stop("Fade in duration cannot be longer than wave length.")

IN<-seq(0,1,length=ndin)
OUT<-seq(0,1,length=ndout)

if(shape=="exp")
  {
  IN<-exp(IN) ; IN<-IN-1 ; IN<-IN/max(IN)   # pb si din ou dout sont ==0
  OUT<-exp(OUT) ; OUT<-OUT-1 ; OUT<-OUT/max(OUT)
  }

if(shape=="cos")
  {
  if (din == 0) IN<-integer(0)
  else {IN<-cos(rev(IN)) ; IN<-IN-min(IN) ; IN<-IN/max(IN)}   # pb si din ou dout sont ==0
  if (dout == 0) OUT<-integer(0)
  else {OUT<-cos(rev(OUT)) ; OUT<-OUT-min(OUT) ; OUT<-OUT/max(OUT)}
  }

MID<-rep(1,nrow(wave)-(length(IN)+length(OUT)))

FADE<-c(IN,MID,rev(OUT))

wave2<-wave*FADE
wave2<-wave2/max(abs(wave2))

if(plot==TRUE)
    {
    oscillo(wave=wave2,f=f,...)
    if(listen == TRUE) {listen(wave2,f=f)}
    }
else
    {
    if (Sample == TRUE){wave2<-as.Sample(as.numeric(wave2), rate=f, bits=16)}
    if(listen == TRUE) {listen(wave2,f=f)}
    return(wave2)
    }
}


################################################################################
##                                FDOPPLER
################################################################################

fdoppler<-function(
f,
c = 340,
vs,
vo = 0,
movs = "toward",
movo = "toward"
)

{
F<-f*((c-vo)/(c-vs))
if(movs == "toward" && movo == "away") F<-f*((c+vo)/(c-vs))
if(movs == "away" && movo == "toward") F<-f*((c-vo)/(c+vs))
if(movs == "away" && movo == "away")   F<-f*((c+vo)/(c+vs))
return(F)
}

################################################################################
##                                FFILTER
################################################################################

ffilter<-function(
wave,
f,
from = FALSE,
to = FALSE,
bandpass = TRUE,
custom = NULL,
wl = 512,
wn="hanning",
Sample = FALSE
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

n<-nrow(wave)
step<-seq(1,n-wl,wl)
Lstep<-length(step)

# first perform a STFT (without overlap nor zero-padding)
z1<-matrix(data=numeric(wl*Lstep),wl,Lstep)
W<-ftwindow(wl=wl,wn=wn)
for(i in step) {z1[,which(step==i)]<-fft(wave[i:(wl+i-1),]*W)}
z1a<-z1[1:(wl/2),]

if (!is.null(custom))
  {
  if(is.matrix(custom)==TRUE) custom<-custom[,2]
  if((length(custom)) != wl/2) stop("custom filter length has to be equal to 'wl'/2")
  z1a<-z1a*(custom/max(custom))
  }
else
  {
  if (from == FALSE & to == FALSE)
  stop("At least one of the 'from' and 'to' arguments has to be set")
  if (from == to)
  stop("'from' and 'to' have to be different")
  if (from == FALSE) from<-0
  if (to == FALSE) to<-f/2
  F<-round(wl*(from/f))
  T<-round(wl*(to/f))
  if (bandpass == TRUE) z1a[-c(F:T),]<-0
  if (bandpass == FALSE) z1a[F:T,]<-0
  }

# generate the mirror part of the fft
z1b<-z1a[nrow(z1a):1,]
# combine both parts of the fft
z2<-rbind(z1a,z1b)
# calculate the Real Part of the reverse fft
z3<-matrix(data=numeric(wl*Lstep),wl,Lstep)
for(i in 1:Lstep) {z3[,i]<-Re(fft(z2[,i],inverse=TRUE)/nrow(z2))}
# manipulation to switch from a matrix to a single vector to be read as a signal
z4<-c(as.vector(z3),rep(0,n-(max(step)+wl-1)))
if (Sample == TRUE){z5<-as.Sample(z4, rate=f, bits=16)}
else z5<-as.matrix(z4)
return(z5)
}


################################################################################
##                                FIELD
################################################################################

field<-function(f,d)
{
c<-wasp(f=f)$c
k<-f/c
kd<-k*d
if(length(d)==1)
  {
  if(kd<0.1) decision<-as.character("You are probably in the near-field, see documentation")
  if(kd>=0.1 & kd<1) decision<-as.character("You are probably at the limit between near-field and far-field, see documentation")
  if(kd>=1) decision<-as.character("You are probably in the far-field, see documentation")
  results<-list(kd=kd,d=decision)
  }
else results<-list(kd=kd)
return(results)
}


################################################################################
##                                FIR
################################################################################

fir<-function(
wave,
f,
from = FALSE,
to = FALSE,
bandpass = TRUE,
custom = NULL,
wl = 512,
wn = "hanning",
listen = FALSE,
Sample = FALSE
)

{
# input
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

# frequency limits of the filter
if (from == FALSE) from <- 0
if (to == FALSE) to <- f/2
from <- round((from * wl)/f)
to <- round((to * wl)/f)
n <- nrow(wave)

# frequency response of the filter
if (!is.null(custom))
    {
    if(is.matrix(custom)==TRUE) custom<-custom[,2]
    if((length(custom)) != wl/2) stop("custom filter length has to be equal to 'wl'/2")
    if (bandpass == TRUE)  {filtspec1 <- c(custom, rev(custom))}
    else                   {filtspec1 <- 1 - c(custom, rev(custom))}
    filtspec1 <- filtspec1/max(filtspec1)
    }
else
    {
    filtspec1 <- rep(1, wl/2)
    if (bandpass == TRUE)  {filtspec1[-(from:to)] <- 0}
    else                   {filtspec1[from:to] <- 0}
    filtspec1 <- c(filtspec1, rev(filtspec1))
    }

# generation of filter pulse
pulse1 <- Re(fft(filtspec1, inverse = TRUE)/length(filtspec1))
pulse1 <- pulse1/max(pulse1)
pulse2 <- c(pulse1[((wl/2)+1):wl], pulse1[-((wl/2+1):wl)])

# window shape
W <- ftwindow(wl = wl, wn = wn)

# filter by convolution between the signal and pulse
wave2<-convolve(wave[,1],pulse2*W,type="filter")

# adds 0s before and after the signal to compensate for the reduction of wave length
wave2<-c(rep(0,wl%/%2),wave2,rep(0,wl%/%2-1))

# delete any potential offset
wave2<-wave2-mean(wave2)
wave2<-as.matrix(wave2)

if(Sample == TRUE){wave2<-as.Sample(as.numeric(wave2), rate=f, bits=16)}
if(listen == TRUE) {listen(wave2,f=f)}
return(wave2)
}


################################################################################
##                                FMA
################################################################################

fma<-function(
wave,
f,
threshold = NULL,
plot = TRUE,
...)

{
ifreq<-ifreq(wave, f=f, threshold=threshold, plot = FALSE)$f
ifreq<-na.omit(ifreq)
spec(ifreq[,2],f=f,plot=plot,...)
}


################################################################################
##                                FTWINDOW
################################################################################

ftwindow<-function(
wl,
wn = "hamming"
)

{
if(wn=="bartlett")  w<-bartlett.w(wl)
if(wn=="blackman")  w<-blackman.w(wl)
if(wn=="flattop")   w<-flattop.w(wl)
if(wn=="hamming")   w<-hamming.w(wl)
if(wn=="hanning")   w<-hanning.w(wl)
if(wn=="rectangle") w<-rectangle.w(wl)
return(w)
}

################################################################################
##                                   FUND
################################################################################

fund<-function(
wave,
f,
wl = 512,
ovlp = 0,
fmax,
threshold = NULL,
plot = TRUE,
xlab = "Time (s)",
ylab = "Frequency (kHz)",
ylim = c(0,f/2000),
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)
if(!is.null(threshold)) {wave<-afilter(wave=wave,f=f,threshold=threshold,plot=FALSE)}
wave<-ifelse(wave==0,yes=1e-6,no=wave)

n<-nrow(wave)
p<-round(n/2)
step<-seq(1,n-wl,wl-(ovlp*wl/100))
N<-length(step)
WL<-wl%/%2
z1<-matrix(data=numeric(wl*N),wl,N)
for(i in step)
  {z1[,which(step==i)]<-Re(fft(log(abs(fft(wave[i:(wl+i-1),]))),inverse=TRUE))}
z2<-z1[1:WL,]
z<-ifelse(z2=="NaN"|z2=="-Inf",yes=0,no=z2)

fmaxi<-f%/%fmax
tfund<-numeric(N)
for (k in 1:N) {tfund[k]<-which.max(z[-c(1:fmaxi),k])}
tfund<-as.numeric(ifelse(tfund==1,yes="NA",no=tfund))
ffund<-f/(tfund+fmaxi-1)

x<-seq(0,n/f,length.out=N)
y<-ffund/1000

if (plot == TRUE)
  {

  plot(x=x, y=y,
  xaxs="i", xlab = xlab,
  yaxs="i", ylab = ylab, ylim = ylim,
  las =1,
  ...)
  }

else return(cbind(x,y))
}


################################################################################
##                                   H
################################################################################

H<-function(
wave,
f,
wl = 512,
envt = "hil",
msmooth = NULL,
ksmooth = NULL
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)
# spectral entropy
spec<-meanspec(wave=wave,f=f,wl=wl,plot=FALSE)
SH<-sh(spec)

# temporal entropy
enve<-env(wave=wave,f=f,envt=envt,msmooth=msmooth,ksmooth=ksmooth,plot=FALSE)
TH<-th(enve)

z<-SH*TH
return(z)
}



################################################################################
##                                HILBERT
################################################################################

hilbert<-function(wave, f)
{
wave<-inputw(wave=wave,f=f)$w
n<-nrow(wave)
ff<-fft(wave)
h<-rep(0,n)
if(n>0 & 2*floor(n/2)==n){h[c(1, n/2+1)]<-1; h[2:n/2]<-2}
else{if(n>0){h[1]<-1; h[2:(n+1)/2]<-2}}
ht<-fft(ff*h,inverse=TRUE)/length(ff)
return(ht)
}


################################################################################
##                                IFREQ
################################################################################

ifreq<-function(
wave,
f,
phase = FALSE,
threshold = NULL,
plot = TRUE,
xlab = "Time (s)",
ylab = NULL,
ylim = NULL,
type = "l",
...
)

{
require(signal)
wave<-hilbert(wave,f=f)
n<-nrow(wave)
# instantaneous phase
phi<-Arg(wave)
# instantaneous unwrapped phase
phi2<-unwrap(phi[,1])
# instantaneous frequency
ifreq<-numeric(length(phi2)-1)
for(i in 1:(length(phi2)-1)){ifreq[i]<-(f/1000)*(abs(phi2[i+1]-phi2[i]))/(2*pi)}
# because the lenghth of ifreq is n-1 (the last point cannot be computed)
# we build the n point as equals to the n-1 point 
ifreq<-c(ifreq,ifreq[length(ifreq)-1])

if(!is.null(threshold))
  {
  wavet<-afilter(wave=wave,f=f,threshold=threshold,plot=FALSE)
  phi[which(wavet[,1]==0)]<-"NA"
  ifreq[which(wavet[-n,1]==0)]<-"NA"
  }

xf<-seq(0,n/f,length.out=n)
xp<-seq(0,n/f,length.out=n)
    
if(plot == TRUE)
  {
  if(phase == FALSE)
    {
    if(is.null(ylab)) {ylab<-"Frequency (kHz)"}
    if(is.null(ylim)) {ylim<-c(0,f/2000)}
    
    plot(x=xf, y=ifreq,
    xaxs="i", xlab=xlab,
    yaxs="i", ylab=ylab, ylim=ylim, 
    type=type, ...)
    }
  else
    {
    if(is.null(ylab)) {ylab<-"Phase (rad)"}
    if(is.null(ylim)) {ylim<-c(-pi,pi)}
    plot(x=xp, y=phi, 
    xaxs="i", xlab=xlab,
    yaxs="i", ylab=ylab, ylim=ylim, 
    type=type, ...)    
    }  
  }
else return(list(f=cbind(xf,ifreq), p=cbind(xp,phi)))
}


################################################################################
##                                LISTEN
################################################################################

listen<-function(
wave,
f,
from = NULL,
to = NULL,
choose = FALSE
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(choose==TRUE)
  { 
	cat("choose start and end positions on the wave\n")
  if (.Platform$OS.type == "windows") flush.console()
  oscillo(wave,f=f)
	coord<-locator(n=2)
  from<-coord$x[1]; a<-round(from*f) ; abline(v=from,col=2,lty=2)
  to<-coord$x[2]; b<-round(to*f); abline(v=to,col=2,lty=2)
	wave<-wave[a:b]
	}
else if(!is.null(from)|!is.null(to))
  {
  if(is.null(from) && !is.null(to)) {a<-1; b<-round(to*f)}
  if(!is.null(from) && is.null(to)) {a<-round(from*f); b<-length(wave)}
	if(!is.null(from) && !is.null(to))
		{
		if (from>to) stop("'from' cannot be superior to 'to'")
		if(from==0) {a<-1} else a<-round(from*f)
		b<-round(to*f)
		}
	wave<-as.matrix(wave[a:b])
  }

wave<-as.Sample(wave[,1]/(2*max(abs(wave[,1]))), rate=f, bits=16)
play(wave)
}


################################################################################
##                                LFS
################################################################################

lfs<-function(
wave,
f,
shift,
wl = 128,
wn="hanning",
Sample = FALSE
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)
n<-nrow(wave)

# alerts concerning the chose of the frequency shift
if (shift == 0) stop("'shift' value cannot be equal to 0")
if (shift>f/2) stop("Positive 'shift' value cannot exceed half of the sampling frequency")
if (shift<(-f/2)) stop("Negative 'shift' value cannot be less than half of the sampling frequency")
if (abs(shift)<f/wl) stop("'shift' value cannot be less than the frequency resolution (f/wl)")
if (wl>n*2) stop("'wl' value is too high, respect wl<length(wave)*2")

step<-seq(1,n-wl,wl)
Lstep<-length(step)
FSH<-abs(shift)

# first perform a STFT (without overlap nor zero-padding)
z1<-matrix(data=numeric(wl*Lstep),wl,Lstep)
W<-ftwindow(wl=wl,wn=wn)
for(i in step) {z1[,which(step==i)]<-fft(wave[i:(wl+i-1),]*W)}
z1<-z1[1:(wl/2),]

S<-round(wl*(FSH/f))

# generate a 0 matrix corresponding to the frequency shift to apply
z2a<-matrix(data=0,nrow=S,ncol=Lstep)

# first case: the frequency shift is positive
if(shift>0)
  {
  z2b<-z1[c(1:(wl/2-S)),]
  z2c<-rbind(z2a,z2b)
  }
# second case: the frequency shift is negative
if(shift<0)
  {
  z2b<-z1[-c(1:S),]
  z2c<-rbind(z2b,z2a)
  }

# generate the mirror part of the fft
z2d<-z2c[nrow(z2c):1,]
# combine both parts of the fft
z2<-rbind(z2c,z2d)
# calculate the Real Part of reverse of the fft
z3<-matrix(data=numeric(wl*Lstep),wl,Lstep)
for(i in 1:Lstep) {z3[,i]<-Re(fft(z2[,i],inverse=TRUE)/nrow(z2))}
# manipulation to swith from a matrix to a single vector to be read as a signal
z4<-c(as.vector(z3),rep(0,n-(max(step)+wl-1)))
if (Sample == TRUE){z5<-as.Sample(z4, rate=f, bits=16)}
else {z5<-as.matrix(z4)}
return(z5)
}


################################################################################
##                               MEANSPEC
################################################################################

meanspec<-function(
wave,
f,
wl = 512,
wn = "hanning",
ovlp = 0,
PSD =  FALSE,
PMF = FALSE,
dB = FALSE,
from = NULL,
to = NULL,
peaks = NULL,
identify = FALSE,
col = "black",
cex = 1,
colpeaks = "red",
cexpeaks = 1,
fontpeaks = 1,
plot = 1,
flab = "Frequency (kHz)",
alab = "Amplitude",
flim = c(0,f/2000),
alim = NULL,
type ="l",
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if (dB == TRUE & PMF == TRUE) stop("PMF cannot be in dB")

if(!is.null(from)|!is.null(to))
  {
  if(is.null(from) && !is.null(to)) {a<-1; b<-round(to*f)}
  if(!is.null(from) && is.null(to)) {a<-round(from*f); b<-length(wave)}
	if(!is.null(from) && !is.null(to))
		{
		if (from>to) stop("'from' cannot be superior to 'to'")
		if(from==0) {a<-1} else {a<-round(from*f)}
		b<-round(to*f)
		}
  wave<-as.matrix(wave[a:b,])
  }

n<-nrow(wave)
N<-wl
step<-seq(1,n-wl,wl-(ovlp*wl/100))		# FT windows
y1<-matrix(data=numeric((wl)*length(step)),wl,length(step))
W<-ftwindow(wl=wl,wn=wn)
for(i in step)
   {y1[,which(step==i)]<-
            Mod(fft(c(wave[i:(wl+i-1),])*W))}
  
y2<-y1[1:(wl/2),]	# to keep only the relevant frequencies (half of the FT)
y3<-y2/max(y2)					      # to get only values between 0 and 1
y4<-apply(y3,MARGIN=1,mean)   # mean computation (by rows)
y5<-y4/max(y4)
# replaces 0 values in spectra that can't be processed by the following log10())
y<-ifelse(y5==0,yes=1e-6,no=y5)

if(PSD == TRUE) y<-y^2

if(PMF == TRUE) y<-y/sum(y)

if(!is.null(peaks))
  {
  check.pks(y)
  p<-peaks(y,peaks)
  respeaks<-seq(y)[p]*f/N/1000
  }

x<-seq(f/1000/wl,f/2000,length.out=N/2)  

if(is.null(alim) == TRUE)
  {
  if (dB == FALSE) alim<-c(0,1.1)
  if (dB == TRUE)  alim<-c(min(20*log10(y)),20)
  if (PMF == TRUE) alim<-c(0,max(y))
  }

if(plot == 1) # plots x-y graph with Frequency as X-axis
	{
    if(dB == TRUE)
	  {
    y<-20*log10(y)	
	  plot(x,y,
		xaxs = "i", xlab = flab, xlim = flim,
		yaxs = "i", yaxt = "s", ylab = alab, ylim = alim,
		cex = cex, col = col,
    type = type, las=1,...)
    }
    else
    {
    if (PMF == FALSE)
      {
      yaxt<-"n"
      ylab<-alab
      }
    else
      {
      yaxt<-"s"
      ylab<-" "
      }
    plot(x,y,
		xaxs = "i", xlab = flab, xlim = flim,
		yaxs = "i", yaxt = yaxt, ylab = ylab, ylim = alim,
		cex = cex, col = col,
    type = type, las = 1,...)
    }

 	  if(identify == TRUE)
    {
    cat("choose points on the spectrum\n")
    if (.Platform$OS.type == "windows") flush.console()
    id<-identify(x=x,y=y,labels=round(x,2),tolerance=0.15,col="red")
    id.freq<-x[id]
    id.amp<-y[id]
    coord<-list(freq = id.freq ,amp = id.amp)
    return(coord)
    }     	
    
    if(!is.null(peaks))                              
    {
    if (dB == TRUE)
    text(seq(y)[p]*f/N/1000, y[p]+5,
            as.character(round(seq(y)[p]*f/N/1000,3)),
            col = colpeaks, cex = cexpeaks, font = fontpeaks)
    else  
    text(seq(y)[p]*f/N/1000, y[p]+0.05,
            as.character(round(seq(y)[p]*f/N/1000,3)),
            col = colpeaks, cex = cexpeaks, font = fontpeaks)
    }
  }

if(plot == 2) # plots x-y graph with Frequency as Y-axis
	{
    if(dB == TRUE)
	  {
    y<-20*log10(y)	
	  plot(y,x,
		xaxs = "i", xlab = alab, xlim = alim,
		yaxs = "i", yaxt = "s", ylab = flab, ylim = flim,
    cex = cex, col = col,
    type = type, las = 1,...)
    }
    else
    {
    if (PMF == FALSE)
      {
      xaxt<-"n"
      xlab<-alab
      }
    else
      {
      xaxt<-"s"
      xlab<-" "
      }
    plot(y,x,
		xaxs = "i", xaxt = xaxt, xlab = xlab, xlim = alim,
		yaxs = "i", ylab = flab, ylim = flim,
    cex = cex, col = col,
    type = type, las = 1,...)
    }
	  
    if(identify == TRUE)
    {
    cat("choose points on the spectrum\n")
    if (.Platform$OS.type == "windows") flush.console()
    id<-identify(x=y,y=x,labels=round(x,2),tolerance=0.15,col="red")
    id.freq<-x[id]
    id.amp<-y[id]
    coord<-list(freq = id.freq ,amp = id.amp)
    return(coord)
    }    
    		
    if(!is.null(peaks))
    {
    if (dB == TRUE)
    text(y[p]+10, seq(y)[p]*f/N/1000,
          as.character(round(seq(y)[p]*f/N/1000,3)),
          col = colpeaks, cex = cexpeaks)
    else  
    text(y[p]+0.1, seq(y)[p]*f/N/1000,
          as.character(round(seq(y)[p]*f/N/1000,3)),
          col = colpeaks, cex = cexpeaks)
    }
  }

if(plot == FALSE) 
  {
  if(dB == TRUE) y<-20*log10(y)
  spec<-cbind(x,y[1:length(y)])	
  if(!is.null(peaks))
      {
      results<-list(spec = spec ,peaks = respeaks)
      return(results)
      }
  else return(spec)
  }
}


################################################################################
##                                MEL
################################################################################

mel<-function(
x,
inverse = FALSE
)

{
y<-1127.01048*log(1+(x/700))
if(inverse==TRUE) y<-700*(exp(x/1127.01048)-1)
return(y)
}


################################################################################
##                                MICSENS
################################################################################

micsens<-function(x,sref=1,inverse=FALSE){
if(inverse==FALSE)
	{
	s<-x/1000
	S<-20*log10(s/sref)
	}
else {S<-1000*sref*10^(x/20)}
return(S)
}


################################################################################
##                                MOREDB
################################################################################

moredB<-function(x)
{
if (is.matrix(x)==TRUE) n<-nrow(x)
if (is.vector(x)==TRUE) n<-length(x)
if (is.numeric(x)==TRUE) n<-length(x)

data1<-as.numeric(x/10)
data2<-as.numeric(n)
for(i in seq(1,n)) {data2[i]<-10^data1[i]}
data3<-10*log10(sum(data2))
return(data3)
}


################################################################################
##                                MUTEW
################################################################################

mutew<-function(
wave,
f,
from = NULL,
to = NULL,
choose = FALSE,
plot = TRUE,
Sample = FALSE,
...
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

n<-nrow(wave)
#wave.muted<-as.matrix(rep(0,n))

if(choose==TRUE)
  { 
	cat("choose start and end positions on the wave\n")
  if (.Platform$OS.type == "windows") flush.console()
  oscillo(wave,f=f)
	coord<-locator(n=2)
  from<-coord$x[1]; a<-round(from*f) ; abline(v=from,col=2,lty=2)
  to<-coord$x[2]; b<-round(to*f); abline(v=to,col=2,lty=2)
	wave.muted<-as.matrix(c(wave[1:(a-1),],rep(0,length(a:b)),wave[(b+1):n,]))
	}

else if(!is.null(from)|!is.null(to))
  {
  if(is.null(from) && !is.null(to))
      {
      b<-round(to*f)
      wave.muted<-as.matrix(c(rep(0,b),wave[(b+1):n,]))
      }

  if(!is.null(from) && is.null(to)) 
      {
      a<-round(from*f)
      wave.muted<-as.matrix(c(wave[1:(a-1),],rep(0,length(a:n))))
      }

  if(!is.null(from) && !is.null(to))
      {
		  if (from > to) stop("'from' cannot be superior to 'to'")
      if (from == 0) {a<-1; b<-round(to*f)}
      else {
      a<-round(from*f)
      b<-round(to*f)}
      wave.muted<-as.matrix(c(wave[1:(a-1),],rep(0,length(a:b)),wave[(b+1):n,]))
    }
  }

if (plot == TRUE) {oscillo(wave.muted,f=f,...)}
else 
    {
    if (Sample == TRUE){wave.muted<-as.Sample(as.numeric(wave.muted), rate=f, bits=16)}
    return(wave.muted)
    }

}


################################################################################
##                                NOISE
################################################################################

noise<-function(
f,
d,
type = "unif",
listen = FALSE,
Sample = FALSE
)

{
if(type=="unif") wave<-as.matrix(runif(d*f,min=-1,max=1))
if(type=="gaussian") wave<-as.matrix(rnorm(d*f))
if (Sample == TRUE){wave<-as.Sample(as.numeric(wave), rate=f, bits=16)}
if (listen == TRUE) {listen(sound,f=f)}
return(wave)
}


################################################################################
##                                OSCILLO
################################################################################

oscillo<-function
(
wave,
f,
from = NULL,
to = NULL,
scroll = NULL,
zoom = FALSE,
k=1,
j=1,
labels = TRUE,
byrow = TRUE,
identify = FALSE,
plot = TRUE,
colwave = "black",
coltitle = "black",
cextitle = 1.2,
fonttitle = 2,
collab = "black",
cexlab = 1,
fontlab = 1,
colline = "black",
colaxis = "black",
coly0 = "lightgrey",
title = FALSE,
xaxt= "s",
yaxt= "n",
bty = "l"
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

p<-k*j

if(is.null(from) && is.null(to)) {a<-0; b<-length(wave); from<-0; to<-length(wave)/f}
if(is.null(from) && !is.null(to)) {a<-1; b<-round(to*f); from<-0}
if(!is.null(from) && is.null(to)) {a<-round(from*f); b<-length(wave); to<-length(wave)/f}
if(!is.null(from) && !is.null(to))
		{
		if (from>to) stop("'from' cannot be superior to 'to'")
		if(from==0) {a<-1} else {a<-round(from*f)}
		b<-round(to*f)
		}
wave<-as.matrix(wave[a:b,])
n<-nrow(wave)

if (plot == TRUE)
{
alim<-max(abs(wave))
# to get a single window view
if (k==1 & j==1)
{
  if (!is.null(scroll))
    {
      if(!is.numeric(scroll)) stop("scroll has to a numeric")
      if(length(scroll)>1) stop("length of scroll cannot be superior to 1")
      if(zoom == TRUE) stop("zoom and scroll cannot be used together")
      if(identify == TRUE) stop("identify and scroll cannot be used together")
      require(rpanel)
      require(tcltk)
      step<-round(seq(0,n,length.out=scroll+1))
      lstep<-length(step)
      pos<-1:(lstep-1)
      plot.dynosc<-function(panel)
      {
        with(panel,
        {
        soscillo(wave = wave, f = f, from = step[pos]/f,
        to=step[pos+1]/f,
        colwave = colwave, collab = collab,
        cexlab = cexlab, fontlab = fontlab, colline = colline,
        colaxis = colaxis, coly0 = coly0, bty = bty,
        tickup=max(abs(wave),na.rm=TRUE), ylim=c(-max(abs(wave)),max(abs(wave))))
        title(main=pos,col.main=coltitle,cex.main=cextitle,font.main=fonttitle)
        }
        )
        panel
      }
      osc.panel <- rp.control("Window")
      rp.slider(osc.panel,pos,from=1,to=lstep-1,resolution=1,
       title = "Window", action=plot.dynosc)
    }

  else
  {
  if (zoom == TRUE)
    {
    par(tcl=0.5, col.axis=colaxis, col=colline,las=0)
    plot(x=seq(from,to,length.out=n), y=wave,
          col=colwave, type="l",
		      xaxs="i", yaxs="i",
		      xlab="", ylab="", ylim=c(-alim,alim),
          xaxt=xaxt, yaxt=yaxt,
		      cex.lab=0.8, font.lab=2,
          bty=bty
		      )
    if (bty == "l" | bty == "o")
          {axis(side=1, col=colline,labels=FALSE)
          axis(side=2, at=max(abs(wave),na.rm=TRUE), col=colline,labels=FALSE)}
	   mtext("Time (s)",col=collab, font=fontlab,side=1,line=3,cex=cexlab)
	   mtext("Amplitude",col=collab, font=fontlab, cex=cexlab,side=2,line=2.5)
	   abline(h=0,col=coly0,lty=2)

    cat("choose start and end positions on the wave\n")
    if (.Platform$OS.type == "windows") flush.console()
    coord<-locator(n=2)
    from<-coord$x[1]; c<-from*f-a
    to<-coord$x[2]; d<-to*f-a
    if (d<c) {c<-d; d<-c}
    wave<-as.matrix(wave[c:d,1])
    n<-nrow(wave)
    }

  op<-par(tcl=0.5, col.axis=colaxis, col=colline,las=0)

  plot(x=seq(from,to,length.out=n), y=wave,
		col=colwave, type="l",
		xaxs="i", yaxs="i",
		xlab="", ylab="", ylim=c(-alim,alim),
		xaxt=xaxt, yaxt=yaxt,
		cex.lab=0.8, font.lab=2,
    	bty=bty)

  if(bty == "l" | bty == "o")
      	{
		axis(side=1, col=colline,labels=FALSE)
      	axis(side=2, at=max(abs(wave),na.rm=TRUE), col=colline,labels=FALSE)
		}

  if(labels == TRUE)
      {
      mtext("Time (s)",col=collab, font=fontlab,side=1,line=3,cex=cexlab)
      mtext("Amplitude",col=collab, font=fontlab, cex=cexlab,side=2,line=3)
	  }

  abline(h=0,col=coly0,lty=2)

  if(is.character(title)) title<-paste(title)
  if (title == FALSE) {title <- paste("")}
  if (title == TRUE) {title<-paste("Total time =",as.character(round(n/f,3)), "s - f =",as.character(f),"Hz")}
  title(main=title, col.main=coltitle, cex.main=cextitle, font.main=fonttitle)

  if (identify == TRUE)
      {
      cat("choose points on the wave\n")
      if (.Platform$OS.type == "windows") flush.console()
      x<-seq(from=from,to=to,length.out=n)
      y<-wave
      id<-identify(x=x, y=y, labels=round(x,3), col="red", plot=TRUE)
      abline(v=(id/f)+from,col="red")
      return(round((id/f)+from,3))
      }
  par(op)
  }
}

# to get a multi-window view
else
{
  if(!is.null(scroll)) stop("scroll cannot be used with a multi-frame window")
  if(zoom == TRUE) stop ("'zoom' does work with a single-frame window only ('k'=1 and 'j'=1)")
  if(identify == TRUE) stop ("'identify' does work with a single-frame window only ('k'=1 and 'j'=1)")
  x<-n%/%p
  def.par <- par(no.readonly = TRUE)
  on.exit(par(def.par))
  m<-matrix(1:p,k,j,byrow=byrow)
	layout(m)
	par(tcl=0.5,oma=c(3,2,2,0.5),
      mar=rep(0,4)+0.8, mgp=c(0,0.15,0),
      col.axis=colaxis, col=colline, las=0)

# plots the first window
	wave1<-as.matrix(wave[0:x,]); n1<-nrow(wave1)
	plot(x=seq(from,from+(x/f),length.out=n1), y=wave1,
		col=colwave, type="l",
		xaxs="i", yaxs="i",
		xlab="", ylab="", ylim=c(-alim,alim),
		xaxt=xaxt, yaxt=yaxt,
    bty=bty)
	axis(side=1, col=colline,labels=FALSE)
	if (bty == "l" | bty == "o")
        {axis(side=2, at=max(abs(wave)), col=colline,labels=FALSE)
        axis(side=1, col=colline,labels=FALSE)}
  abline(h=0,col=coly0,lty=2)

# title
if(is.character(title)) title<-paste(title)
if (title == FALSE) {title <- paste("")}
if (title == TRUE)
	{
	title<-paste("Window time =",
                as.character(round(n/(p*f),3)),"s - Total time =",
                as.character(round(n/f,3)), "s - f =",
                as.character(f),"Hz")
	}
mtext(paste(title),side=3,line=0.4,col=coltitle,cex=cextitle,font=fonttitle,outer=TRUE)

# X-Y labels
if (labels == TRUE)
  {
  mtext("Time (s)",col=collab, side=1,line=1.5, font=fontlab,cex=cexlab,outer=TRUE)
	mtext("Amplitude",col=collab, side=2, font=fontlab,cex=cexlab,
        line=0.4,outer=TRUE)
  }

# plots following windows
for(i in 1:(p-1))
  {
	xx<-((i*n)%/%p)+1
	yy<-((i+1)*n)%/%p
	wave2<-as.matrix(wave[xx:yy,]); n2<-nrow(wave2)
	plot(x=seq(from+(xx/f),from+(yy/f),length.out=n2), y=wave2,
		col=colwave, type="l",
		xaxs="i", yaxs="i",
		xlab="", ylab="", ylim=c(-alim,alim),
		xaxt=xaxt, yaxt=yaxt,
    bty=bty)

	if (bty == "l" | bty == "o")
        {axis(side=2, at = max(abs(wave)), col=colline,labels=FALSE)
       	axis(side=1, col=colline,labels=FALSE)}
  abline(h=0,col=coly0,lty=2)
  }
}
}
else return (wave)
}


################################################################################
##                                OSCILLOST
################################################################################

oscilloST<-function
(
wave1,
wave2 = NULL,
f,
from = NULL,
to = NULL,
identify = FALSE,
plot = TRUE,
colwave1 = "black",
colwave2 = "blue",
coltitle = "black",
collab = "black",
cexlab = 1,
fontlab = 1,
colaxis = "black",
coly01 = "grey47",
coly02 = "black",
title = FALSE,
bty = "l"
)

{
input1<-inputw(wave1,f=f,channel=1) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
if(is.Sample(wave1)$test==TRUE && channels(wave1)==2) {wave2<-inputw(wave1,channel=2)$w}
else wave2<-inputw(wave2,f=f,channel=1)$w

if(class(wave1)=="Sample" | class(wave2)=="Sample")
  {
  if(channels(wave1)==2)
  {
  f<-wave1$rate ; 
  wave2<-as.matrix(wave1$sound[2,])
  wave1<-as.matrix(wave1$sound[1,])
  }
  else
  {
  f<-wave1$rate ; wave1<-as.matrix(wave1$sound[1,])
  if(class(wave2)=="Sample" & channels(wave2)==1) {f<-wave2$rate ; wave2<-as.matrix(wave2$sound[1,])}
  }
  }

if (plot==TRUE)
  {
  op<-par(mfrow=c(2,1),oma=c(5,3,2,2),mar=rep(0,4))
  
	oscillo(wave=wave1,f=f,
  from=from,to=to,zoom=FALSE,labels=FALSE,xaxt="n",
  colaxis=colaxis,colwave=colwave1,coly0=coly01,
  bty=bty)
  
	oscillo(wave=wave2,f=f,
  from=from,to=to,identify=identify,zoom=FALSE,labels=FALSE,
  colaxis=colaxis,colwave=colwave2,coly0=coly02,
  bty=bty)

  mtext("Time (s)",col=collab,font=fontlab,cex=cexlab,side=1,line=2.8,outer=TRUE)
  mtext("Amplitude",col=collab,font=fontlab,cex=cexlab,side=2,line=1.5,outer=TRUE)

  par(op)
  }

else return (cbind(wave1,wave2))
}


################################################################################
##                                PASTEW
################################################################################

pastew<-function(
wave1,
wave2,
f,
at = "end",
choose = FALSE,
plot = FALSE,
marks = TRUE,
Sample = FALSE,
...)

{
input1<-inputw(wave=wave1,f=f) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
wave2<-inputw(wave=wave2,f=f)$w

n<-nrow(wave2)

if(choose==TRUE)
  { 
	cat("choose position on the wave\n")
  if (.Platform$OS.type == "windows") flush.console()
  oscillo(wave2,f=f)
	coord<-locator(n=1)
  at<-coord$x[1]; abline(v=at,col=2,lty=2)
	}
else
	{
	if(at=="start")  at<-0
	if(at=="middle") at<-n/(2*f)
	if(at=="end")    at<-n/f
	}

pos<-round(at*f)
wave2a<-as.matrix(wave2[c(1:pos),1])
wave2b<-as.matrix(wave2[c(pos:n),1])
wave3<-rbind(wave2a,wave1,wave2b)

if (plot == TRUE)
  {
  def.par <- par(no.readonly = TRUE)
  on.exit(par(def.par))
  par(mfrow=c(3,1),oma=c(0,0.1,0,0))
  oscillo(wave1,f=f,k=1,j=1)
  title(main="signal to be pasted")
  oscillo(wave2,f=f,k=1,j=1)
  title(main="signal to be completed")  
  oscillo(wave3,f=f,k=1,j=1)
  title(main="resulting signal")
    if (marks == TRUE)
    {
    abline(v=at, col="red", lty=2)
    abline(v=at+(nrow(wave1))/f, col="red", lty=2)
    }
  }
else    
    {
    if (Sample == TRUE){wave3<-as.Sample(as.numeric(wave3), rate=f, bits=16)}
    return(wave3)
    }
}


################################################################################
##                                PULSE
################################################################################

pulse<-function(
dbefore,
dpulse,
dafter,
f,
plot = FALSE,
Sample = FALSE,
...
)

{
wave<-as.matrix(c(rep(0,dbefore*f),rep(1,dpulse*f),rep(0,dafter*f)))
if(plot==TRUE) oscillo(wave,f=f,...)
else    
    {
    if (Sample == TRUE){wave<-as.Sample(as.numeric(wave), rate=f, bits=16)}
    return(wave)
    }
}




################################################################################
##                                Q
################################################################################

Q<-function(
spec,
f = NULL,
level = -3,
plot = TRUE,
colval = "red",
cexval = 1,
fontval = 1,
flab = "Frequency (kHz)",
alab = "Relative amplitude (dB)",
type = "l",
...)

{
if(is.null(f)==TRUE)
  {
  if(is.vector(spec)==TRUE) stop("'f' is missing")  
  else if(is.matrix(spec)==TRUE) f<-spec[nrow(spec),1]*2000
  }

if(is.matrix(spec)==TRUE) spec<-spec[,2]

range<-c(f/2000/length(spec),f/2000)

if (max(spec) == 1) stop ("data must be in dB")
if (which.max(spec) == 1) 
    stop ("maximal peak cannot be the first value of the spectrum") 

n0<-length(spec)

spec1<-approx(spec,n=102400)
spec1<-as.matrix(spec1$y)
n1<-nrow(spec1)
level2<-round(max(spec1[,1]),1)+level

f0<-which.max(spec1[,1])
specA<-as.matrix(spec1[1:f0,1])
nA<-nrow(specA)
specB<-as.matrix(spec1[f0:nrow(spec1),1])
f1<-which(round(specA,1) == level2)
f1khz<-((f1[length(f1)]/n1)*(range[2]-range[1]))+range[1]
f2<-which(round(specB,1) == level2)+(nA-1)
f2khz<-((f2[1]/n1)*(range[2]-range[1]))+range[1]

Q<-f0/(f2[1]-f1[length(f1)])

# plot based on original data (=> spectrum)
if (plot == TRUE)
	{
	x<-seq(range[1],range[2],length.out=n0)
	plot(x=x,y=spec,xlab=flab,ylab=alab,type=type,...)
	arrows(f1khz,level2,f2khz,level2,length=0.1,col=colval,code=3,angle=15)
	text(paste("Q =",as.character(round(Q,2))),x=f2khz,y=level2,pos=4,
      col=colval, cex=cexval, font=fontval)
	}

return(Q)
}


################################################################################
##                                REPW
################################################################################

repw<-function(
wave,
f,
times = 2,
plot = FALSE,
Sample = FALSE,
...
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

wave1<-as.matrix(rep(wave,times=times))

if (plot == TRUE){oscillo(wave=wave1,f=f,...)}
else
    {
    if (Sample == TRUE){wave1<-as.Sample(as.numeric(wave1), rate=f, bits=16)}
    return(wave1)
    }
}


################################################################################
##                                REVW
################################################################################

revw<-function(
wave,
f,
env = TRUE,
ifreq = TRUE,
plot = FALSE,
Sample = FALSE,
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(env == FALSE & ifreq == FALSE) stop ("Both arguments 'env' and 'ifreq' cannot be set to FALSE.")

if(env==TRUE & ifreq == TRUE) {wave2<-as.matrix(rev(wave[,1]))}
else
	{
	wave.e<-env(wave[,1],f=f,plot=FALSE)
	wave.p<-ifreq(wave[,1],f=f,plot=FALSE)$p[,2]
	if(env==TRUE & ifreq== FALSE) {wave2<-as.matrix(rev(wave.e)*cos(wave.p))}
	if(env==FALSE & ifreq == TRUE) {wave2<-as.matrix(wave.e*cos(rev(wave.p)))}
	}

if (plot == TRUE) {oscillo(wave=wave2,f=f,...)}
else 
    {
    if(Sample == TRUE){wave2<-as.Sample(as.numeric(wave2), rate=f, bits=16)}
    return(wave2)
    }
}



################################################################################
##                                RESAMP
################################################################################


resamp<-function(
wave,
f,
g,
Sample = FALSE
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)$w

n<-nrow(wave)
if (g==f) stop ("'f' and 'g' must be different")
if (g<f)  {r<-f/g; wave1<-wave[seq(1,n,by=r),1]}
if (g>f)  {s<-(n*g)/f; wave1<-approx(wave,n=s)$y}

if (Sample == TRUE){wave1<-as.Sample(as.numeric(wave1), rate=g, bits=16)}
else wave1<-as.matrix(wave1)

return(wave1)
}


################################################################################
##                                RMAM
################################################################################

rmam<-function(
wave,
f,
plot = FALSE,
listen = FALSE,
Sample = FALSE,
...
)

{
wave<-as.matrix(wave/Mod(hilbert(wave,f=f)))

if(plot==TRUE)
    {
    oscillo(wave=wave,f=f,...)
    if(listen == TRUE) {listen(wave,f=f)}
    }
else
    {
    if(Sample == TRUE) {wave<-as.Sample(as.numeric(wave), rate=f, bits=16)}
    if(listen == TRUE) {listen(wave,f=f)}
    return(wave)
    }
}


################################################################################
##                                RMOFFSET
################################################################################

rmoffset<-function(
wave,
f,
plot = FALSE,
...
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)
wave2<-wave-mean(wave)
if (plot==TRUE) oscillo(wave=wave2,f=f,...)
else return(wave2)
}


################################################################################
##                               SAVEWAV
################################################################################

savewav<-function(
wave,
f,
filename = NULL
)

{
if (is.null(filename) == TRUE) filename <- paste(as.character(deparse(substitute(wave))),".wav",sep="")
if(class(wave)=="Sample") {saveSample(wave, filename=filename, overwrite=TRUE)}
else
  {
  wave<-wave/(max(abs(wave))*1.5) # this avoids overclipping problems
  wave<-as.Sample(as.numeric(wave), rate=f, bits=16)
   saveSample(wave, filename=filename, overwrite=TRUE)
  }
}


################################################################################
##                               SETENV
################################################################################

setenv<-function
(
wave1,
wave2,
f,
envt="hil",
msmooth = NULL,
ksmooth = NULL,
plot = FALSE,
listen = FALSE,
Sample = FALSE,
...
)

{
input1<-inputw(wave=wave1,f=f) ; wave1<-input1$w ; f<-input1$f ; rm(input1)
wave2<-inputw(wave=wave2,f=f)$w

wave1<-rmoffset(wave1,f=f)
wave1<-rmam(wave1,f=f)
wave1<-wave1/max(abs(wave1))

wave2<-rmoffset(wave2,f=f)
wave2.env<-env(wave2,f=f,envt=envt,msmooth=msmooth,ksmooth=ksmooth,plot=FALSE)
wave2.env<-approx(wave2.env, n=nrow(wave1))$y

wave3<-wave1*wave2.env
wave3<-wave3/max(abs(wave3))

if(plot == TRUE)
    {
    oscillo(wave=wave3,f=f,...)
    if(listen == TRUE) {listen(wave3,f=f)}
    }
else
    {
    if(Sample == TRUE){wave3<-as.Sample(as.numeric(wave3), rate=f, bits=16)}
    if (listen == TRUE) {listen(wave3,f=f)}
    return(wave3)
    }
}


################################################################################
##                               SFM
################################################################################

sfm<-function(spec)

{
if(is.matrix(spec) == TRUE) spec <- spec[, 2]
if(any(spec<0)) stop("Data do not have to be in dB")
if(sum(spec)==0) flat<-NA
# undersample spec if too long because prod(spec) tends towards zero
if (length(spec) > 400)
	{
	step<-seq(1,length(spec),by=round(length(spec)/256))
	spec<-spec[step]
	} 
spec<-ifelse(spec==0,yes=1e-5,no=spec)
# PMF multiplied by 10 to avoid values between 0 and 1 that will make gm=0
spec<-spec/sum(spec)*100
n<-length(spec)
geo<-prod(spec)^(1/n)
ari<-mean(spec)
flat<-geo/ari

return(flat)
}


################################################################################
##                               SH
################################################################################

sh<-function(
spec
)

{
if(is.matrix(spec)==TRUE) spec<-spec[,2]
if(any(spec<0)) stop("Data do not have to be in dB")
N<-length(spec)
if (sum(spec)==0) z<-NA 
else
 {
 spec[spec==0]<-1e-7
 # normalisation tel que la somme des valeurs du spectre = 1
 specn<-spec/sum(spec)
 z<- -sum(specn*log2(specn))/log2(N)
 }
return(z)
}


################################################################################
##                                SIMSPEC
################################################################################


simspec<-function(
spec1,
spec2,
f = NULL,
plot = FALSE,
type = "l",
lty1 = 1,
lty2 = 2,
lty3 = 3,
col1 = 2,
col2 = 4,
col3 = 1,
flab = "Frequency (kHz)",
alab = "Amplitude (percentage)",
flim = c(0,f/2000),
alim = c(0,100),
legend = TRUE,
...
)

{
leg<-c(as.character(deparse(substitute(spec1))),as.character(deparse(substitute(spec2))))

if(is.null(f)==TRUE)
  {
  if(is.vector(spec1)==TRUE & is.vector(spec2)==TRUE) stop("'f' is missing")  
  else
    {
    if(is.matrix(spec1)==TRUE) f<-spec1[nrow(spec1),1]*2000
    else if(is.matrix(spec2)==TRUE) f<-spec2[nrow(spec2),1]*2000
    }
  }

if(is.matrix(spec1)==TRUE && ncol(spec1)==2) spec1<-spec1[,2]
if(is.matrix(spec2)==TRUE && ncol(spec2)==2) spec2<-spec2[,2]

n1<-length(spec1)
n2<-length(spec2)

if (n1 != n2) stop("spec1 and spec2 must have the same length")
if (any(spec1 < 0) | any(spec2 < 0))
  stop("spectra (spec 1 and/or spec 2) do not have to be in dB")

S1<-100*(pmin(spec1,spec2)/pmax(spec1,spec2))
S<-sum(S1)/n1

if (plot==TRUE)
  {
  x<-seq((f/2000)/n1,f/2000,length.out=n1)
  plot(x=x, y=spec1*100, type=type, lty=lty1, col=col1,
    xlim=flim, xaxs="i",
    ylim=alim, yaxs="i",
    axes=FALSE, ann=FALSE)
  par(new=TRUE)
  plot(x=x, y=spec2*100, type=type, lty=lty2, col=col2,
    xlim=flim, xaxs="i",
    ylim=alim, yaxs="i",
    axes=FALSE, ann=FALSE)
  par(new=TRUE)
  plot(x=x, y=S1, type=type, lty=lty3, col=col3,
      xaxs="i", xlab=flab, xlim=flim,
      yaxs="i", ylim=alim, ylab=alab,...)
  if(legend==TRUE) legend("topleft", col=c(col1,col2),lty=c(lty1,lty2),legend=leg)
  }

return(S)
}

################################################################################
##                                SPEC
################################################################################

spec<-function(
wave,
f,
wl = 512,
wn = "hanning",
PSD = FALSE,
PMF = FALSE,
dB = FALSE,
at = NULL,
from = NULL,
to = NULL,
peaks = NULL,
identify = FALSE,
col = "black",
cex = 1,
colpeaks = "red",
cexpeaks = 1,
fontpeaks = 1,
plot = 1,
flab = "Frequency (kHz)",
alab = "Amplitude",
flim = c(0,f/2000),
alim = NULL,
type ="l",
...)

{
if (dB == TRUE & PMF == TRUE) stop("PMF cannot be in dB")

input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(!is.null(from)|!is.null(to))
  {
  if(is.null(from) && !is.null(to)) {a<-1; b<-round(to*f)}
  if(!is.null(from) && is.null(to)) {a<-round(from*f); b<-length(wave)}
	if(!is.null(from) && !is.null(to))
		{
		if (from>to) stop("'from' cannot be superior to 'to'")
		if(from==0) {a<-1} else a<-round(from*f)
		b<-round(to*f)
		}
  wave<-as.matrix(wave[a:b,])
  }

if(!is.null(at))
  {
  c<-round(at*f)
  wl2<-wl%/%2
  wave<-as.matrix(wave[(c-wl2):(c+wl2),])
  }
  
n<-nrow(wave)
W<-ftwindow(n,wn=wn)
wave<-wave*W
y1<-Mod(fft(wave[,1]))
y11<-y1[1:(n%/%2)]
y2<-y11/max(y11)
# replaces 0 values in spectra that can't be processed by the following log10()
y<-ifelse(y2==0,yes=1e-6,no=y2)

if(PSD == TRUE) y<-y^2

if(PMF == TRUE) y<-y/sum(y)

if(!is.null(peaks))
  {
  check.pks(y)
  p<-peaks(y,peaks)
  respeaks<-seq(y)[p]*f/n/1000
  }

if(!is.null(at)) x<-seq(f/1000/wl,f/2000,length.out=n%/%2)
else x<-seq(f/1000/n,f/2000,length.out=n%/%2)

if(is.null(alim) == TRUE)
  {
  if (dB == FALSE) alim<-c(0,1.1)
  if (dB == TRUE)  alim<-c(min(20*log10(y)),20)
  if (PMF == TRUE) alim<-c(0,max(y))
  }

if(plot == 1) # plots x-y graph with Frequency as X-axis
	{
    if(dB == TRUE)
	  {
    y<-20*log10(y)
	  plot(x=x,y=y,
		xaxs = "i", xlab = flab, xlim = flim,
		yaxs = "i", yaxt = "s", ylab = alab, ylim = alim,
		col = col, cex = cex,
    type = type, las = 1,
    ...)
    }
    else
    {
    if (PMF == FALSE)
      {
      yaxt<-"n"
      ylab<-alab
      }
    else
      {
      yaxt<-"s"
      ylab<-" "
      }
    plot(x=x,y=y,
		xaxs="i", xlab=flab, xlim = flim,
		yaxs="i", yaxt=yaxt, ylab = ylab, ylim=alim,
    col = col, cex = cex,
    type = type, las = 1,
    ...)
    }

    if(identify == TRUE)
    {
    cat("choose points on the spectrum\n")
    if (.Platform$OS.type == "windows") flush.console()
    id<-identify(x=x,y=y,labels=round(x,2),tolerance=0.15,col="red")
    id.freq<-x[id]
    id.amp<-y[id]
    coord<-list(freq = id.freq ,amp = id.amp)
    return(coord)
    }

    if(!is.null(peaks))
    {
    if (dB == TRUE)
    text(seq(y)[p]*f/n/1000, y[p]+5,
              as.character(round(seq(y)[p]*f/n/1000,3)),
              col = colpeaks, cex = cexpeaks, font = fontpeaks)
    else
    text(seq(y)[p]*f/n/1000, y[p]+0.05,
              as.character(round(seq(y)[p]*f/n/1000,3)),
              col = colpeaks, cex = cexpeaks, font = fontpeaks)
    }
  }

if(plot == 2) # plots x-y graph with Frequency as Y-axis
	{
    if(dB == TRUE)
	  {
    y<-20*log10(y)
	  plot(x=y,y=x,
		xaxs = "i", xlab = alab, xlim = alim,
		yaxs = "i", yaxt = "s", ylab = flab, ylim = flim,
    col = col, cex = cex,
    type = type, las = 1,
    ...)
    }
    else
    {
    if (PMF == FALSE)
      {
      xaxt<-"n"
      xlab<-alab
      }
    else
      {
      xaxt<-"s"
      xlab<-" "
      }
    plot(x=y,y=x,
		xaxs = "i", xaxt = xaxt, xlab = xlab, xlim = alim,
		yaxs = "i", ylab = flab, ylim = flim,
    col = col, cex = cex,
    type = type, las = 1,
    ...)
    }


    if(identify == TRUE)
    {
    cat("choose points on the spectrum\n")
    if (.Platform$OS.type == "windows") flush.console()
    id<-identify(x=y,y=x,labels=round(x,2),tolerance=0.15,col="red")
    id.freq<-x[id]
    id.amp<-y[id]
    coord<-list(freq = id.freq ,amp = id.amp)
    return(coord)
    }

    if(!is.null(peaks))
    {
    if (dB == TRUE)
    text(y[p]+10, seq(y)[p]*f/n/1000,
              as.character(round(seq(y)[p]*f/n/1000,3)),
              col = colpeaks, cex = cexpeaks, font= fontpeaks)
    else
    text(y[p]+0.1, seq(y)[p]*f/n/1000,
              as.character(round(seq(y)[p]*f/n/1000,3)),
              col = colpeaks, cex = cexpeaks, font= fontpeaks)
    }
  }

if(plot == FALSE)
  {
  if(dB == TRUE) y<-20*log10(y)
  spec<-cbind(x,y[1:length(y)])
  if(!is.null(peaks))
      {
      results<-list(spec = spec ,peaks = respeaks)
      return(results)
      }
  else return(spec)
  }
}


################################################################################
##                                SPECPROP
################################################################################

specprop<-function(
spec,
f = NULL,
str=FALSE,
flim=NULL,
plot=FALSE,
type="l",
...)

{
if(is.null(f)==TRUE)
  {
  if(is.vector(spec)==TRUE) stop("'f' is missing")  
  else if(is.matrix(spec)==TRUE) f<-spec[nrow(spec),1]*2000
  }

if(is.matrix(spec)==TRUE) spec<-spec[,2]  
L<-length(spec)
wl<-L*2
if(any(spec<0)) stop("The frequency spectrum to be analysed should not be in dB")
if(f/wl<0.5)    stop("Frequency resolution is to high (<0.5 hz)")

# modifcation of the frequency limits
if(!is.null(flim))
	{
	spec<-spec[(flim[1]*1000*wl/f):(flim[2]*1000*wl/f)]
	L<-length(spec)
	}

# to get all spectrum values >1 
# it is necessary to multiply the PMF spectrum by a factor of 10
s<-spec/sum(spec)
MS<-min(s) 
if(diff(range(s))<0.01)
    {
    if(1e-2<MS & MS<1e-1)   S<-round(s*1e5)
    if(1e-3<MS & MS<1e-2)   S<-round(s*1e6)
    if(1e-4<MS & MS<1e-3)   S<-round(s*1e7)
    if(1e-5<MS & MS<1e-4)   S<-round(s*1e8)
    if(1e-6<MS & MS<1e-5)   S<-round(s*1e9)
    if(1e-7<MS & MS<1e-6)   S<-round(s*1e10)
    if(1e-8<MS & MS<1e-7)   S<-round(s*1e12)
    if(1e-9<MS & MS<1e-8)   S<-round(s*1e13)
    if(1e-10<MS & MS<1e-9)  S<-round(s*1e14)
    if(1e-11<MS & MS<1e-10) S<-round(s*1e15)
    if(1e-12<MS & MS<1e-11) S<-round(s*1e16)
    }
else
    {
    if(1e-2<MS & MS<1e-1)   S<-round(s*1e2)
    if(1e-3<MS & MS<1e-2)   S<-round(s*1e3)
    if(1e-4<MS & MS<1e-3)   S<-round(s*1e4)
    if(1e-5<MS & MS<1e-4)   S<-round(s*1e5)
    if(1e-6<MS & MS<1e-5)   S<-round(s*1e6)
    if(1e-7<MS & MS<1e-6)   S<-round(s*1e7)
    if(1e-8<MS & MS<1e-7)   S<-round(s*1e8)
    if(1e-9<MS & MS<1e-8)   S<-round(s*1e9)
    if(1e-10<MS & MS<1e-9)  S<-round(s*1e10)
    if(1e-11<MS & MS<1e-10) S<-round(s*1e11)
    if(1e-12<MS & MS<1e-11) S<-round(s*1e12)
    }

# generate the frequency vector in Hz to avoid values <1
if(is.null(flim)) {X<-round(seq(from=f/wl,to=f/2,length.out=L))}
else {X<-round(seq(from=flim[1]*1000,to=flim[2]*1000,length.out=L))}

# generate the variable from the distribution function
V<-rep(X,S)

# descriptive statistics computation in Hz
mean<-mean(V)
sd<-sd(V)
sem<-sd/sqrt(L)                          # standard error of the mean
median<-median(V)
mad<-mad(V)
mode<-X[which.max(S)]                   # dominant frequency
Q25<-quantile(V, names = FALSE)[2]
Q75<-quantile(V, names = FALSE)[4]
IQR<-IQR(V)
cent<-sum(X*s)                          # centroid
z<-sum(s-mean(s)) ; w<-sd(s)
skew<-(sum((s-mean(s))^3)/(L-1))/w^3    # skewness
kurt<-(sum((s-mean(s))^4)/(L-1))/w^4    # kurtosis
sfm<-sfm(s)                             # spectral flatness measure
sh<-sh(s)                               # spectral entropy
prec<-f/wl                              # frequency precision 

# plot
if(plot==1)
  {
  par(mar=c(5,5,4,2)+0.1)
  plot(x=X/1000,y=s,type=type,
  xlab="Frequency (kHz)", xaxs="i",
  ylab="",yaxs="i",
  las=1,
  ...)
  mtext("Probability",side=2,line=4)
  segments(x0=mode/1000, y0=0, x1=mode/1000, y1=s[which(X==mode)], col=4)
  segments(x0=median/1000, y0=0, x1=median/1000, y1=s[which(X==median)], col=2)
  segments(x0=Q25/1000, y0=0, x1=Q25/1000, y1=s[which(X==Q25)], col=2, lty=2)
  segments(x0=Q75/1000, y0=0, x1=Q75/1000, y1=s[which(X==Q75)], col=2, lty=3)
  legend("topright", legend=c("Q25","median","Q75","mode"),col=c(2,2,2,4),
        lty=c(2,1,3,1),bty="n")
  }
  
if(plot==2)
  {
  C<-cumsum(s)
  plot(x=X/1000,y=C,type=type,
  xlab="Frequency (kHz)", xaxs="i",
  ylab="Cumulated probability",yaxs="i",
  las=1,
  ...)
  segments(x0=mode/1000, y0=0, x1=mode/1000, y1=C[which(X==mode)], col=4)
  segments(x0=0, y0=C[which(X==mode)], x1=mode/1000, y1=C[which(X==mode)], col=4)
  segments(x0=median/1000, y0=0, x1=median/1000, y1=max(C)/2, col=2)
  segments(x0=0, y0=max(C)/2, x1=median/1000, y1=max(C)/2, col=2)
  segments(x0=Q25/1000, y0=0, x1=Q25/1000, y1=max(C)/4, col=2, lty=2)
  segments(x0=0, y0=max(C)/4, x1=Q25/1000, y1=max(C)/4, col=2, lty=2)
  segments(x0=Q75/1000, y0=0, x1=Q75/1000, y1=max(C)*3/4, col=2, lty=3)
  segments(x0=0, y0=max(C)*3/4, x1=Q75/1000, y1=max(C)*3/4, col=2,lty=3)
  legend("bottomright", legend=c("Q25","median","Q75","mode"),col=c(2,2,2,4),
        lty=c(2,1,3,1),bty="n")
  }

if(plot==FALSE)
  {
  results<-list(mean=mean,sd=sd,sem=sem,median=median,mad=mad,mode=mode,
                Q25=Q25,Q75=Q75,IQR=IQR,
                cent=cent,skewness=skew,kurtosis=kurt,
                sfm=sfm,sh=sh,
                prec=prec)
  if(str==TRUE) str(results,digits.d=5,give.head=FALSE) else return(results)
  }
}


################################################################################
##                                SPECTRO
################################################################################

spectro<-function(
wave,
f,
wl = 512,
wn = "hanning",
zp = 0,
ovlp = 0,
plot = TRUE,
grid = TRUE,
osc = FALSE,
scale = TRUE,
cont = FALSE,
collevels = seq(-30,0,1),
palette = spectro.colors,
contlevels = seq (-30,0,10),
colcont = "black",
colbg = "white", 
colgrid = "black",
colaxis = "black",
collab = "black",
plot.title =
    title(main = "", xlab = "Time (s)",
    ylab = "Frequency (kHz)"),
scalelab = "Amplitude\n(dB)",
scalefontlab = 1,
scalecexlab =0.75,
axisX = TRUE,
axisY = TRUE,
tlim = NULL,
trel = TRUE,
flim = NULL,
flimd = NULL,
listen = FALSE,
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if(!is.null(tlim)) wave<-cutw(wave,f=f,from=tlim[1],to=tlim[2])

# n<-nrow(wave)

# dynamic vertical zoom (modifications of analysis parameters)
if (!is.null(flimd))
  {
  # zoom magnification
  mag<-round((f/2000)/(flimd[2]-flimd[1]))
  # new parameters
  wl<-wl*mag
  if (ovlp==0) ovlp<-100
  ovlp<-100-round(ovlp/mag)
  # use of normal flim for following axis modifications
  flim<-flimd
  }
  
n<-nrow(wave)
step<-seq(1,n-wl,wl-(ovlp*wl/100))		# FT windows

# STFT
z<-stft(wave=wave,f=f,wl=wl,zp=zp,step=step,wn=wn)	  

# X axis settings
if(!is.null(tlim) && trel==TRUE) {X<-seq(tlim[1],tlim[2],length.out=length(step))}
else {X<-seq(0,n/f,length.out=length(step))}

# vertical zoom
if(is.null(flim)==TRUE) {Y<-seq(0,f/2000,length.out=nrow(z))}
else
  {
  fl1<-flim[1]*nrow(z)*2000/f
  fl2<-flim[2]*nrow(z)*2000/f
  z<-z[fl1:fl2,]
  Y<-seq(flim[1],flim[2],length.out=nrow(z))
  }
  
Z<-t(z)
   
if (plot==TRUE)
 	{
  Zlim<-range(Z, finite = TRUE) 
  if (osc==TRUE & scale==TRUE)
    {
    def.par <- par(no.readonly = TRUE)
    on.exit(par(def.par))
    layout(matrix(c(1, 2 ,3, 0), nc = 2, byrow=TRUE),
              widths = c(6, 1), heights=c(3,1))
    par(mar=c(0,4.1,1,0),las=1,cex=1,col=colaxis,col.axis=colaxis,col.lab=collab,bg=colbg)
    filled.contour.modif2(x=X ,y=Y, z=Z, levels=collevels, nlevels=20,
			plot.title=plot.title, color.palette=palette,axisX=FALSE, axisY=axisY)
  	if(grid == TRUE) grid(nx=NA, ny=NULL, col=colgrid)
    if(cont==TRUE){contour(X,Y,Z,add=TRUE,levels=contlevels,nlevels=5,col=colcont,...)}
    if(colaxis != colgrid) abline(h=0,col=colaxis) else abline(h=0,col=colgrid)
    par(mar=c(0,1,4.5,3),las=0)
    dBscale(collevels=collevels,palette=palette,fontlab=scalefontlab,
      cexlab=scalecexlab,collab=collab,textlab=scalelab,colaxis=colaxis)
    par(mar=c(5,4.1,0,0),las=0,col="white",col=colaxis,col.lab=collab)

    soscillo(wave=wave,f=f,bty="o",collab=collab,colaxis=colaxis,
    colline=colaxis,ylim=c(-max(abs(wave)),max(abs(wave))),
    tickup=max(abs(wave),na.rm=TRUE),...)
    }
    
  if (osc==FALSE & scale==TRUE)
    {
    def.par <- par(no.readonly = TRUE)
    on.exit(par(def.par))
    layout(matrix(c(1, 2), nc = 2, byrow=TRUE), widths = c(6, 1))
    par(mar=c(5,4.1,1,0),las=1,cex=1,col=colaxis,col.axis=colaxis,col.lab=collab,bg=colbg)
    filled.contour.modif2(x=X ,y=Y, z=Z, levels=collevels, nlevels=20,
			plot.title=plot.title, color.palette=palette,axisX=axisX, axisY=axisY)
   	if(grid==TRUE) grid(nx=NA, ny=NULL, col=colgrid)
		if(colaxis!=colgrid) abline(h=0,col=colaxis) else abline(h=0,col=colgrid)
    if(cont==TRUE){contour(X,Y,Z,add=TRUE,levels=contlevels,nlevels=5,col=colcont,...)}
    par(mar=c(5,1,4.5,3),las=0)
    dBscale(collevels=collevels,palette=palette,fontlab=scalefontlab,
      cexlab=scalecexlab,collab=collab,textlab=scalelab,colaxis=colaxis)
    }

  if (osc==TRUE & scale==FALSE)
    {
    def.par <- par(no.readonly = TRUE)
    on.exit(par(def.par))
    layout(matrix(c(2,1), nr = 2, byrow=TRUE), heights=c(3,1))
    par(mar=c(5.1,4.1,0,2.1), las=0, bg=colbg)
    soscillo(wave=wave,f=f,bty="o",collab=collab,colaxis=colaxis,colline=colaxis,
    tickup=max(abs(wave),na.rm=TRUE), ylim=c(-max(abs(wave)),max(abs(wave))),...)
    par(mar=c(0,4.1,2.1,2.1), las=1)
    filled.contour.modif2(x=X ,y=Y, z=Z, levels=collevels, nlevels=20,
			plot.title=plot.title, color.palette=palette, axisX=FALSE, axisY=axisY,
      col.lab=collab,colaxis=colaxis)		
    if(grid==TRUE) grid(nx=NA, ny=NULL, col=colgrid)
    if(cont==TRUE){contour(X,Y,Z,add=TRUE,levels=contlevels,nlevels=5,col=colcont,...)}
    if(colaxis!=colgrid) abline(h=0,col=colaxis) else abline(h=0,col=colgrid)
    }
  
  if (osc==FALSE & scale==FALSE)
   {
   par(las=1, col=colaxis, col.axis=colaxis, col.lab=collab,bg=colbg,...)
   filled.contour.modif2(x=X ,y=Y, z=Z, levels=collevels, nlevels=20,
			plot.title=plot.title, color.palette=palette, axisX=axisX, axisY=axisY,
      col.lab=collab,colaxis=colaxis)		
   if (grid==TRUE) grid(nx=NA, ny=NULL, col=colgrid)
   if(cont==TRUE){contour(X,Y,Z,add=TRUE,levels=contlevels,nlevels=5,col=colcont,...)}
   if(colaxis!=colgrid) abline(h=0,col=colaxis) else abline(h=0,col=colgrid)
   } 
if (listen == TRUE) {listen(wave, f=f)}
  }
else return(z)
}

################################################################################
##                                SPECTRO3D
################################################################################

spectro3D<-function(
wave,
f,
wl = 512,
wn = "hanning",
zp = 0,
ovlp = 0,
plot = TRUE,
magt = 10,
magf = 10,
maga = 2,
palette = rev.terrain.colors)

{
require(rgl)
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)
n <- nrow(wave)
step <- seq(1, n - wl, wl - (ovlp * wl/100))
z <- stft(wave = wave, f =f, wl = wl, zp = zp, step = step, wn = wn)
if (plot == FALSE)
return(z)
else {
     X <- magt * (1:ncol(z))
     Y <- magf * (1:nrow(z))
     Z <- maga * z
     Xat <- seq(magt, magt * ncol(z), by = (magt * ncol(z))/4)
     Yat <- seq(magf, magf * nrow(z), by = (magf * nrow(z))/4)
     Zat <- seq(min(Z), maga, by = abs(min(Z))/4)
     Xlab <- as.character(round(seq(0, n/f, by = n/(4 * f)),1))
     Ylab <- as.character(round(seq((f/1000)/(wl + zp), f/2000,by = f/(4*2000)), 1))
     Zlab <- as.character(round(seq(min(Z)/maga, 0, by = abs(min(Z))/(4*maga)), 1))
     Zlim <- range(Z)
     Zlen <- Zlim[2] - Zlim[1] + 1
     colorlut <- palette(Zlen)
     col <- colorlut[Z - Zlim[1] + 1]
     rgl.clear()
     rgl.bbox(color = "white", emission = "gray8", specular = "gray",
            shininess = 50, alpha = 0.8, xat = Yat, xlab = Ylab,
            xunit = 0, yat = Zat, ylab = Zlab, yunit = 0, zat = Xat,
            zlab = Xlab, zunit = 0)
     rgl.texts(x = 1, z = magt * ncol(Z)/2, y = min(Z), text = "Time (s)", color = "white")
     rgl.texts(z = 1, x = magf * nrow(Z)/2, y = min(Z), text = "Frequency (kHz)", color = "white")
     rgl.texts(x = 1, z = 0, y = 0, text = "Amplitude (dB)", color = "white")
     rgl.surface(Y, X, Z, color = col, back = "lines")
     }
}


################################################################################
##                                SYMBA
################################################################################
symba<-function(
x,
y = NULL,
symb = 5,
collapse = TRUE,
entropy = "abs",
plot = FALSE,
type = "l",
lty1 = 1,
lty2 = 2,
col1 = 2,
col2 = 4,
cex1 = 0.75,
cex2 = 0.75,
xlab = "index",
ylab = "Amplitude",
legend = "TRUE",
...)

{
# input x
s1<-discrets(x=x, symb=symb, collapse=FALSE)
# frequency of each symbols
freq1a<-table(s1,dnn="symbol frequency in the sequence")
# entropy of the sequence
freq1b<-as.vector(freq1a)
freq1c<-freq1b/sum(freq1b)
if(entropy=="abs") h1<- -sum(freq1c*log2(freq1c))
else if(entropy=="rel") h1<- -sum(freq1c*log2(freq1c))/log2(length(freq1c))

if(is.null(y))
	{
	if(plot==TRUE)
		{
		if(symb==3) {s1<-c(NA,s1)} else if(symb==5) {s1<-c(NA,s1,NA)}
		plot(x,type=type,lty=lty1,xlab=xlab,ylab=ylab,...)
		text(x=x,labels=s1,col=col1, cex=cex1)
		}
	else 
		{
		if(collapse==TRUE) s1<-paste(s1,collapse="")
		return(list(s1=s1,freq1=freq1c, h1=h1))
		}
	}

if(!is.null(y))
	{
	if(length(x)!=length(y)) {stop("x and y should have the same length")}
	# input y
	y<-inputw(wave = y,f = NULL)$w
	s2<-discrets(y, symb=symb, collapse=FALSE)
	# frequency of each symbols
	freq2a<-table(s2,dnn="symbol frequency in the sequence")
	# entropy of the sequence
	freq2b<-as.vector(freq2a)
	freq2c<-freq1b/sum(freq2b)
	if(entropy=="abs") h2<- -sum(freq2c*log2(freq2c))
	else if(entropy=="rel") h2<- -sum(freq2c*log2(freq2c))/log2(length(freq2c))
	# joint entropy
	# frequency of each pair of symbols
	freq12<-table(paste(s1,s2,sep=""))
	freq12<-as.vector(freq12)
	freq12<-freq12/sum(freq12)
	# joint entropy
	if(entropy=="abs") h12<- -sum(freq12*log2(freq12))
	else if(entropy=="rel") h12<- -sum(freq12*log2(freq12))/log2(length(freq12))
	# mutual information
	I<-h1+h2-h12
	if(plot==TRUE)
		{
		if(symb==3) {s1<-c(NA,s1);s2<-c(NA,s2)} else {s1<-c(NA,s1,NA);s2<-c(s2,NA)}
		plot(x,type=type, col=col1, lty=lty1,ylim=c(min(c(x,y)),max(c(x,y))),xlab=xlab,ylab=ylab,...)
		text(x=x,labels=s1, col=col1, cex=cex1)
		lines(y,type=type, col=col2,lty=lty2)
		text(x=y,labels=s2, col=col2, cex=cex2)
		if(legend==TRUE) legend("topright",c("x","y"), col=c(col1,col2),lty=c(lty1,lty2))
		}
	else
		{
		if(collapse==TRUE) {s1<-paste(s1,collapse=""); s2<-paste(s2,collapse="")} 
		return(list(s1=s1,freq1=freq1c, h1=h1, s1=s2,freq2=freq2c, h2=h2, I=I))
		}
	}
}


################################################################################
##                                SYNTH
################################################################################

synth<-function(
f,
d,
cf,
a = 1,
shape = NULL,
p = 0,
am = c(0,0),
fm = c(0,0,0),
plot = FALSE,
listen = FALSE,
Sample = FALSE,
...
)

{
n<-round(f*d)

amp<-am[1]/100  # AM modulation percentage
amf<-am[2]  # AM modulation frequency
fme<-fm[1]  # FM sinusoidal excursion
fmf<-fm[2]  # FM sinusoidal frequency
fmE<-fm[3]  # FM linear excursion

t <- seq(0, d*2*pi, length.out = n)


if (fme==0 && fmf!=0)          stop("FM sinusoidal excursion has to be set")
if (fme!=0 && fmf==0 && fmE==0) stop("FM sinusoidal frequency or FM linear excursion has to be set")
if (fme!=0 && fmf==0 && fmE!=0) stop("FM sinusoidal frequency has to be set")

if (fmE>0) freq<-seq(0,fmE/2,length.out=f*d) else freq<-rev(seq(fmE/2,0,length.out=n))

if (fme==0 & fmf==0) {sound<-(1+amp*cos(amf*t))*sin((cf*t)+(freq*t)+p)}

if (fme!=0 & fmf!=0)
  {
  if (fmE == 0)       sound<-(1+amp*cos(amf*t))*sin(cf*t+(fme/fmf)*sin(fmf*t+p)+p)
  else                sound<-(1+amp*cos(amf*t))*sin(cf*t+(fme/fmf)*sin(fmf*t+p)+(freq*t)+p)
  }

if(!is.null(shape))
  {
  if (shape=="incr") {S<-seq(0,1,length.out=n)}
  if (shape=="decr") {S<-seq(1,0,length.out=n)}
  if (shape=="sine") {S<-sin(seq(0,pi,length.out=n))}
  if (shape=="tria")
    {
    if(n%%2 == 1) S<-c(seq(0,1,length.out=n%/%2),seq(1,0,length.out=n%/%2+1))  # if n is odd
    else S<-c(seq(0,1,length.out=n%/%2),seq(1,0,length.out=n%/%2)) # if n is even
    }
  sound<-S*sound
  }

sound<-as.matrix(a*(sound/max(abs(sound))))


if(plot == TRUE)
    {
    spectro(sound, f=f,...)
    if(listen == TRUE) {listen(sound,f=f)}
    }
else
    {
    if(Sample == TRUE){sound<-as.Sample(as.numeric(sound), rate=f, bits=16)}
    if(listen == TRUE) {listen(sound,f=f)}
    return(sound)
    }
}



################################################################################
##                                TH
################################################################################

th<-function(
env
)

{
N<-length(env)

if (sum(env)==0) stop ("Caution! There is no signal in this data set! The temporal entropy is null!")
if (sum(env)/(N*env[1]) == 1 | sum(env)/N == 1) stop("Caution! This is a square signal. The temporal entropy is null!")
if (any(env<0))  stop ("data must be an envelope obtained using oscillo()")

env[env==0]<-1e-7
# normalisation tel que la somme des valeurs de l'enveloppe = 1
envn<-env/sum(env)
z<--sum(envn*log2(envn))/log2(N)

return(z)
}


################################################################################
##                                TIMER
################################################################################

timer<-function(
wave,
f,
threshold,
smooth = NULL,
plot = TRUE,
plotthreshold = TRUE,
col = "black",
colval = "red",
xlab = "Time (s)",
ylab = "Amplitude",
...)


{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

n<-nrow(wave)
thres<-max(abs(wave))*(threshold/100)

if (!is.null(smooth))
  {
  z0<-abs(wave[0:n,])
  step<-seq(1,n-smooth,smooth)
  z1<-numeric(length(step))
  for(i in step)
    {z1[which(step==i)]<-mean(z0[i:(i+smooth)])}
  data<-as.matrix(z1)
  n<-nrow(data)
  thres<-max(data)*(threshold/100)
  f<-f/smooth
  wave1<-ts(z1,start=0,end=n/f,freq=f)
  }
else
  wave1<-ts(abs(wave[0:n,]),start=0,end=n/f,freq=f)

wave2<-ifelse(wave1<=thres,1,2)
wave3<-ts(wave2,start=0,end=n/f,freq=f)

# add successive values in wave1,
# values of 3 corresponds to the end of a silence or signal period
wave4<-numeric(n)  
for (i in 1:(n-1))  {wave4[i]<-wave2[i]+wave2[i+1]}

# sets a value of 3 at the first and last point of the signal
wave4[1]<-3
wave4[n]<-3

# gives the indeces of the end of a pause or signal period
wave5<-which(wave4==3)

# calculates the interval index between two successive ZC
nn<-length(wave5)
wave6<-numeric(nn-1)
for (i in 1:(nn-1)) {wave6[i]<-wave5[i+1]-wave5[i]}
# calculates signal and pause durations
y<-wave6/f

if (wave2[1]==1)  # if the file starts with a pause
  {
  pause<-y[seq(1,nn-1,by=2)]
  signal<-y[seq(2,nn-1,by=2)]
  }
  
else             # if the file starts with a signal
  {
  signal<-y[seq(1,nn-1,by=2)]
  pause<-y[seq(2,nn-1,by=2)]
  }
  
# computes the signal/pause ratio = duty cycle
ratio<-sum(signal)/sum(pause)

if (plot == TRUE)
  {
  plot(wave1/max(abs(wave1)),xlab=xlab,ylab=ylab,yaxt="n",ylim=c(0,1+0.1),col=col,...)
  if (plotthreshold == TRUE)
      {
      abline(h=thres, col=colval,lty=2)
      mtext(paste(as.character(threshold),"%"),
          side=2,line=0.5,at=thres,las=1,col=colval,cex=0.8)
      }
  par(new=TRUE)
  plot(wave3,xlab="",ylab="",yaxt="n",type="l",col=colval,ylim=c(1,2+0.1),...)

  wave8<-numeric(nn-1)
  for (i in 2:nn) {wave8[i]<-((wave5[i]-wave5[i-1])/2)+wave5[i-1]}
      
  if (wave2[1]==1)  # if the file starts with a pause
  {
  wave8.1<-wave8[seq(2,nn,by=2)]/f
  wave8.2<-wave8[seq(3,nn,by=2)]/f
  }
  else              # if the file starts with a signal
  {
  wave8.2<-wave8[seq(2,nn,by=2)]/f
  wave8.1<-wave8[seq(3,nn,by=2)]/f
  }
      
  ypl<-as.character(round(pause,2))
  ysl<-as.character(round(signal,2))
  text(x=wave8.1,y=1.075,ypl,col=colval,cex=0.8)
  text(x=wave8.2,y=2.075,ysl,col=colval,cex=0.8)
  
  }
else
  {
  timer<-list(s = signal,p = pause, r = ratio)
  return(timer)
  }
  
}


################################################################################
##                                WASP
################################################################################

wasp<-function(
f,
t = 20,
c = NULL,
s = NULL,
d = NULL,
medium = "air")

{
if(medium == "air")
  {
  if (!is.null(d)) stop("Depth (d) is not a valuable argument for air medium")
  if (!is.null(s)) stop("Salinity (s) is not a valuable argument for air medium")
  if (!is.null(c)) C<-c
  else C<-331.4+0.6*t
  }
  
if(medium == "sea")
  {
  if(!is.null(c)) C<-c
  if(is.null(s))  stop("Please specify a salinity value (parts per thousand) for sea medium")
  if(is.null(d))  stop("Please specify a depth value (m) for sea medium")
  else 
    {
    C<-1448.96+4.591*t-(5.304e-2)*t^2+(2.374e-4)*t^3+1.34*(s-35)+(1.63e-2)*d+(1.675e-7)*d^2-(1.025e-2)*t*(s-35)-(7.139e-13)*t*d^3
    }  
  }
  
if(medium == "fresh")
  {
  if (!is.null(c)) C<-c
  if (!is.null(d)) stop("Depth (d) is not a valuable argument for freshwater medium")
  if (!is.null(s)) stop("Salinity (s) is not a valuable argument for freshwater medium")
  else 
    {
    C<-1.402385e3+5.038813*t-(5.799136e-2)*t^2+(3.287156e-4)*t^3-(1.398845e-6)*t^4+(2.787860e-9)*t^5
    }
  }

lambda<-C/f  
results<-list(l=lambda,c=C)
return(results)
}


################################################################################
##                                WAV2FLAC
################################################################################

wav2flac<-function(file, reverse=FALSE, overwrite=FALSE, exename=NULL, path2exe=NULL)
{
if(.Platform$OS.type == "unix")
		{
		if(missing(exename)) exename<-"flac"
  	if(missing(path2exe)) {exe<-exename} else{exe<-paste(path2exe,exename,sep="/")}
		e<-system(paste(exename, file),ignore.stderr = TRUE)
		if(reverse==TRUE){e<-system(paste(exe, "-d", file),ignore.stderr = TRUE)}
		}
		
if(.Platform$OS.type == "windows")
		{
		if(missing(exename)) exename<-"flac.exe"
  	if(missing(path2exe)) {exe<-paste("c:/Program Files/FLAC/",exename,sep="")} else {exe<-paste(path2exe,exename,sep="/")}
  	e<-system(paste(shQuote(exe),shQuote(file,type="cmd"), sep=" "),ignore.stderr = TRUE)
  	if(reverse==TRUE){e<-system(paste(shQuote(exe),'-d',shQuote(file,type="cmd"),sep=" "),ignore.stderr = TRUE)}
		}

if(e>0) {stop("File not found or wrong format/encoding")}
if(overwrite==TRUE){unlink(file)}
}


################################################################################
##                                ZAPSILW
################################################################################

zapsilw<-function(
wave,
f,
threshold = 5,
plot = TRUE,
Sample = FALSE,
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

wave1<-afilter(wave,f=f,threshold=threshold,plot=FALSE)
wave2<-as.matrix(wave1[wave1!=0])

if (plot == TRUE)
    {
	def.par <- par(no.readonly = TRUE)
	on.exit(par(def.par))    
	par(mfrow=c(2,1),oma=c(0,0.1,0,0))
	oscillo(wave=wave, f=f, ...)
	title(main="original")
	oscillo(wave=wave2, f=f,...)
	title(main="silence removed")
    }
else
    {
    if (Sample == TRUE){wave2<-as.Sample(as.numeric(wave2), rate=f, bits=16)}
    return(wave2)
    }
}


################################################################################
##                                ZC
################################################################################

zc<-function(
wave,
f,
plot = TRUE,
interpol = 1,
threshold = NULL,
xlab = "Time (s)",
ylab = "Frequency (kHz)",
ylim = c(0,f/2000),
...)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if (interpol > 5)
  {
  cat("please wait...")
  if (.Platform$OS.type == "windows") flush.console()
  }

n<-nrow(wave)

if(!is.null(threshold)) wave<-afilter(wave=wave,f=f,threshold=threshold,plot=FALSE)
  
if (interpol > 1)
  {
  waveinterpol<-approx(wave,n=n*interpol)
  wave<-as.matrix(waveinterpol$y)
  F<-f*interpol
  }
else F<-f

# replaces null or positive values by 1 and negative values by 2  
wave1<-ifelse(wave>=0,1,2) 

# adds successive values in wave1, values of 3 corresponds to ZC
wave2<-numeric(n*interpol)  
for (i in 1:((n*interpol)-1))  {wave2[i]<-wave1[i]+wave1[i+1]}
# replaces 2 by 0
wave3<-ifelse(wave2==2, yes=0, no=wave2)
# replaces 4 by 0
wave4<-ifelse(wave3==4, yes=0, no=wave3)
# replaces 3 by their index
wave5<-replace(wave4,which(wave4==3),which(wave4==3))

# computes the period T between two successive zc 
wave6<-which(wave2==3) 
nn<-length(wave6) 
wave7<-numeric(nn)
for (i in 2:(nn-1)) {wave7[i]<-wave6[i+1]-wave6[i-1]}

# replaces index by T
wave8<-replace(wave5,which(wave5!=0),wave7)

# calculates the frequency
wave9<-F/(wave8)/1000 
y<-replace(wave9,which(wave9==Inf),NA)

x<-seq(0,n/f,length.out=n*interpol)
if (plot == TRUE){plot(x = x, y = y, xlab=xlab, ylab=ylab, las=1, ylim = ylim,...)}
else return(cbind(x,y))
}



  
                       ###########################
                       ###########################
                       ### ACCESSORY FUNCTIONS ###
                       ###########################
                       ###########################


################################################################################
##                                BARTLETT.W
################################################################################ 

bartlett.w<-function (n)
{
if(n <= 0) stop("'n' must be a positive integer")

n<-n-1
m<-n%/%2
w<-c((2*(0:(m-1)))/n, 2-((2*(m:n))/n))
return(w)
}


################################################################################
##                                BLACKMAN.W
################################################################################ 

blackman.w<-function (n)
{
if(n <= 0) stop("'n' must be a positive integer")
n <- n-1
w <- 0.42-0.5*cos(2*pi*(0:n)/n)+0.08*cos(4*pi*(0:n)/n)
return(w)
}


################################################################################
##                       FILLED.CONTOUR.MODIF2
################################################################################ 
# modification of filled.contour in graphics by Ross Ihaka

filled.contour.modif2<-function (x = seq(0, 1, len = nrow(z)),
    y = seq(0, 1, len = ncol(z)), z, xlim = range(x, finite = TRUE),
    ylim = range(y, finite = TRUE), zlim = range(z, finite = TRUE),
    levels = pretty(zlim, nlevels), nlevels = 20, color.palette = cm.colors,
    col = color.palette(length(levels) - 1), plot.title, plot.axes, key.title,
    asp = NA, xaxs = "i", yaxs = "i", las = 1, axisX = TRUE, axisY = TRUE,...) 
{
    if (missing(z)) {
        if (!missing(x)) {
            if (is.list(x)) {
                z <- x$z
                y <- x$y
                x <- x$x
            }
            else {
                z <- x
                x <- seq(0, 1, len = nrow(z))
            }
        }
        else stop("no 'z' matrix specified")
    }
    else if (is.list(x)) {
        y <- x$y
        x <- x$x
    }
    if (any(diff(x) <= 0) || any(diff(y) <= 0)) 
        stop("increasing 'x' and 'y' values expected")
    plot.new()
    plot.window(xlim, ylim, "", xaxs = xaxs, yaxs = yaxs, asp = asp)
    if (!is.matrix(z) || nrow(z) <= 1 || ncol(z) <= 1) 
        stop("no proper 'z' matrix specified")
    if (!is.double(z)) 
        storage.mode(z) <- "double"
    .Internal(filledcontour(as.double(x), as.double(y), z, as.double(levels), 
        col = col))
    if (missing(plot.axes))
      {
        if(axisX)
            {
            title(main="", xlab="",ylab="")
            axis(1)
            }
        if(axisY)
            {
            title(main="", xlab="",ylab="")
            axis(2)
            }
      }
    box()
    if (missing(plot.title)) 
        title(...)
    else plot.title
    invisible()
}


################################################################################
##                                FLATTOP.W
################################################################################ 

flattop.w<-function (n)
{
if(n <= 0) stop("'n' must be a positive integer")
n<-n-1
w<-0.2156-0.4160*cos(2*pi*(0:n)/n)+0.2781*cos(4*pi*(0:n)/n)
-0.0836*cos(6*pi*(0:n)/n)+0.0069*cos(8*pi*(0:n)/n)   
return(w)
}


################################################################################
##                                HAMMING.W
################################################################################ 

hamming.w<-function (n)
{
if(n <= 0) stop("'n' must be a positive integer")
n<-n-1
w<-0.54-0.46*cos(2*pi*(0:n)/n)
return(w)
}


################################################################################
##                                HANNING.W
################################################################################ 

hanning.w<-function (n)
{
if(n <= 0) stop("'n' must be a positive integer")
n<-n-1
w<-0.5-0.5*cos(2*pi*(0:n)/n)
return(w)
}


################################################################################
##                                INPUTW
################################################################################ 

inputw<-function(wave, f, channel=1)
{
if(is.vector(wave))      {f<-f ; wave <- as.matrix(wave)}
# mts objects are matrix by default, there is then a conflict between is.matrix and is.mts
if(is.matrix(wave) && !is.mts(wave)) {f<-f ; wave <- wave[,channel,drop=FALSE]}  
if(is.ts(wave))          {f<-frequency(wave) ; wave <- as.matrix(wave)} 
if(is.mts(wave))         {f<-frequency(wave) ; wave <- as.matrix(wave[, channel])} 
if(is.Sample(wave)$test) {f<-wave$rate ; wave <- as.matrix(wave$sound[channel, ])}
if(class(wave)=="Wave")
  {
  f <- wave@samp.rate  
  if(channel==1) {wave <- as.matrix(wave@left)}   
  if(channel==2) {wave <- as.matrix(wave@right)}     
  }
return(list(w=wave,f=f))
}


################################################################################
##                         PEAKS, PEAKSIGN, CHECK.PCKS
################################################################################
## Author: Martin Maechler, Date: 25 Nov 2005
## Martin Maechler <maechler@stat.math.ethz.ch>
## Peaksign: return (-1 / 0 / 1) if series[i] is ( trough / "normal" / peak )

peaks <- function(series, span = 3, do.pad = TRUE) {
    if((span <- as.integer(span)) %% 2 != 1) stop("'span' must be odd")
    s1 <- 1:1 + (s <- span %/% 2)
    if(span == 1) return(rep.int(TRUE, length(series)))
    z <- embed(series, span)
    v <- apply(z[,s1] > z[, -s1, drop=FALSE], 1, all)
    if(do.pad) {
        pad <- rep.int(FALSE, s)
        c(pad, v, pad)
    } else v
}

peaksign <- function(series, span = 3, do.pad = TRUE)
{
    if((span <- as.integer(span)) %% 2 != 1 || span == 1)
        stop("'span' must be odd and >= 3")
    s1 <- 1:1 + (s <- span %/% 2)
    z <- embed(series, span)
    d <- z[,s1] - z[, -s1, drop=FALSE]
    ans <- rep.int(0:0, nrow(d))
    ans[apply(d > 0, 1, all)] <- as.integer(1)
    ans[apply(d < 0, 1, all)] <- as.integer(-1)
    if(do.pad) {
        pad <- rep.int(0:0, s)
        c(pad, ans, pad)
    } else ans
}

check.pks <- function(y, span = 3)
    stopifnot(identical(peaks( y, span), peaksign(y, span) ==  1),
              identical(peaks(-y, span), peaksign(y, span) == -1))


################################################################################
##                                RECTANGLE.W
################################################################################ 

rectangle.w<-function (n)
{
if(n <= 0) stop("'n' must be a positive integer")
w<-rep(1,n)
return(w)
}


################################################################################
##                                REV.CM.COLORS
################################################################################
## rev.cm.colors, reversion of cm.colors in grDevices package
## originally by R Development Core Team and contributors worldwide

rev.cm.colors<-
function (x)
{
    n<-x
    if ((n <- as.integer(n[1])) > 0) {
        even.n <- n%%2 == 0
        k <- n%/%2
        l1 <- k + 1 - even.n
        l2 <- n - k + even.n
        rev(c(if (l1 > 0) hsv(h = 6/12, s = seq(0.5, ifelse(even.n, 
            0.5/k, 0), length = l1), v = 1), if (l2 > 1) hsv(h = 10/12, 
            s = seq(0, 0.5, length = l2)[-1], v = 1)))
    }
    else character(0)
}



################################################################################
##                                REV.GRAY.COLORS.1
################################################################################ 
rev.gray.colors.1<-
function (x)
gray(seq(from = 1^1.7, to = 0, length = x)^(1/1.7))



################################################################################
##                                REV.GRAY.COLORS.2
################################################################################ 
rev.gray.colors.2<-
function (x)
gray(seq(from = 1, to = 0, length = x))



################################################################################
##                                REV.HEAT.COLORS
################################################################################
## rev.heat.colors, reversion of heat.colors in grDevices package
## originally by R Development Core Team and contributors worldwide 

rev.heat.colors<-
function (x) 
{
    n<-x
    if ((n <- as.integer(n[1])) > 0) {
        j <- n%/%4
        i <- n - j
        rev(c(rainbow(i, start = 0, end = 1/6), if (j > 0) hsv(h = 1/6, 
            s = seq(from = 1 - 1/(2 * j), to = 1/(2 * j), length = j), 
            v = 1)))
    }
    else character(0)
}



################################################################################
##                        REV.TERRAIN.COLORS
################################################################################
## rev.terrain.colors, reversion of terrain.colors in grDevices package
## originally by R Development Core Team and contributors worldwide 

rev.terrain.colors<-
function (x)
{
    n<-x
    if ((n <- as.integer(n[1])) > 0) {
        k <- n%/%2
        h <- c(4/12, 2/12, 0/12)
        s <- c(1, 1, 0)
        v <- c(0.65, 0.9, 0.95)
        rev(c(
        hsv(h = seq(h[1], h[2], length = k),
        s = seq(s[1], s[2], length = k),
        v = seq(v[1], v[2], length = k)),
        
        hsv(h = seq(h[2], h[3], length = n - k + 1)[-1],
        s = seq(s[2], s[3], length = n - k + 1)[-1],
        v = seq(v[2], v[3], length = n - k + 1)[-1])
        ))
    }
    else character(0)
}



################################################################################
##                                REV.TOPO.COLORS
################################################################################
## rev.topo.colors, reversion of topo.colors in grDevices package
## originally by R Development Core Team and contributors worldwide 

rev.topo.colors<-
function (x) 
{
    n<-x
    if ((n <- as.integer(n[1])) > 0) {
        j <- n%/%3
        k <- n%/%3
        i <- n - j - k
        rev(c(if (i > 0) hsv(h = seq(from = 43/60, to = 31/60, length = i)), 
            if (j > 0) hsv(h = seq(from = 23/60, to = 11/60, 
                length = j)), if (k > 0) hsv(h = seq(from = 10/60, 
                to = 6/60, length = k), s = seq(from = 1, to = 0.3, 
                length = k), v = 1)))
    }
    else character(0)
}



################################################################################
##                                SOSCILLO
################################################################################

soscillo<-function
(
wave,
f,
from = FALSE,
to =FALSE,
colwave = "black",
coltitle = "black",
collab = "black",
colline = "black",
colaxis = "black",
coly0 = "grey47",
cexlab = 1,
fontlab = 1,
title = FALSE,
xaxt="s",
yaxt="n",
tickup = NULL,
... 
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

if (from|to)
  {
  if (from == 0) {a<-1; b<-round(to*f)}
  if (from == FALSE) {a<-1; b<-round(to*f);from<-0}
  if (to == FALSE) {a<-round(from*f); b<-nrow(wave);to<-nrow(wave)/f}
  else {a<-round(from*f); b<-round(to*f)}
  wave<-as.matrix(wave[a:b,])
  n<-nrow(wave)
  }
else {n<-nrow(wave) ; from<-0 ; to<-n/f}

par(tcl=0.5, col.axis=colaxis, col=colline, col.lab=collab,las=0)

wave<-ts(wave[0:n,], start=from, end=to, freq=f)

plot(wave,
		col=colwave, type="l",
		xaxs="i", yaxs="i",
		xlab="", ylab="",
		xaxt=xaxt, yaxt=yaxt, bty="l",
		...)
axis(side=1, col=colline,labels=FALSE)
axis(side=2, at=tickup, col=colline,labels=FALSE)

mtext("Time (s)",col=collab,font=fontlab,cex=cexlab,side=1,line=3)
mtext("Amplitude",col=collab,font=fontlab,cex=cexlab,side=2,line=3)

abline(h=0,col=coly0,lty=2)
}



################################################################################
##                                SSPECTRO
################################################################################

sspectro <- function
(
wave,
f,
wl = 512,
wn="hanning"
)

{
input<-inputw(wave=wave,f=f) ; wave<-input$w ; f<-input$f ; rm(input)

n<-nrow(wave)
step<-seq(1,n-wl,wl)		# FT windows

z1<-matrix(data=numeric(wl*length(step)),wl,length(step))

for(i in step)
  {
  W<-ftwindow(wl=wl,wn=wn)
  z1[,which(step==i)]<- Mod(fft(wave[i:(wl+i-1),]*W))
  }

z2<-z1[1:(wl/2),]
z3<-z2/max(z2)
return(z3)
}



################################################################################
##                                SPECTRO.COLORS
################################################################################

spectro.colors<-
function (n)
{
if ((n <- as.integer(n[1])) > 0)
 {
 j <- n%/%3
 k <- n%/%3
 i <- n - j - k
 c(if (i > 0) hsv(h = seq(from = 31/60, to = 43/60, length = i), s = seq(0,1,length=i)),
   if (j > 0) hsv(h = seq(from = 21/60, to = 9/60, length = j), v = seq(0.5,0.8,length=j)),
   if (k > 0) hsv(h = seq(from = 8/60, to = 1/60, length = k), s = seq(from = 0.5, to = 1, length = k), v=1))
 }
else character(0)
}

################################################################################
##                                 STFT
################################################################################

stft<-function(
wave,
f,
wl,
zp,
step,
wn
)

{
wave<-inputw(wave=wave,f=f)$w

z1<-matrix(data=numeric((wl+(zp))*length(step)),wl+zp,length(step))
zpl<-zp%/%2
if(zpl==0)
  {
  W<-ftwindow(wl=wl,wn=wn)
  for(i in step)
  {z1[,which(step==i)]<-Mod(fft(wave[i:(wl+i-1),]*W))}
  }

else
  {
  W<-ftwindow(wl=wl+zp,wn=wn)
  for(i in step)
  {z1[,which(step==i)]<-
  Mod(fft(c(1:zpl,wave[i:(wl+i-1),],1:zpl)*W))}
  }	

# to keep only the relevant frequencies (half of the FT)
z2<-z1[1:((wl+zp)/2),]	
# to get only values between 0 and 1
z3<-z2/max(z2)					
# replaces 0 values in spectra (that can't be processed by the following log10())
z4<-ifelse(z3==0,yes=1e-6,no=z3)
# to get dB values
z<-20*log10(z4)[-1,]
return(z)	
}


################################################################################
##                                 TEMP.COLORS
################################################################################

temp.colors<-function (n)
{
    if ((n <- as.integer(n[1])) > 0) {
        j <- n%/%3
        k <- n%/%3
        i <- n - j - k
        c(
        if (i > 0) hsv(h=seq(from=44/60, to=31/60, length=i), s=seq(from=1, to=0.3, length=i), v=1),
        if (j > 0) hsv(h=seq(from=31/60, to=8/60,  length=j), s=seq(from=0.3, to=0.6, length=j), v=1),
        if (k > 0) hsv(h=seq(from= 8/60, to=1/60,  length=k), s=seq(from=0.6, to=1, length=k), v=1)
        )
    }
    else character(0)
}