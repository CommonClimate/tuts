#' Spectral analysis of time-uncertain time series using Lomb-Scargle periodogram
#'
#' \code{tuls} computes multiple power estimates using the Lomb-Scargle algorithm and simulated realizations of
#' timings of observations. Timings are simulated with normal distribution \emph{ti~N(ti.mu,ti.sd)},
#' and sorted in ascending order to ensure non-overlapping feature of observations.
#'
#' @param y A vector of observations.
#' @param ti.mu A vector of estimates of timings of observations.
#' @param ti.sd A vector of standard deviations of timings.
#' @param n.sim A number of simulations.
#' @param ... A list of optional parameters. The list contains thinning oversamlping parameter,
#' the default value is ofac=4, confidence interval, the default value is CI=0.99, and the number
#'  of simulated timings, wiith the default vale set to n.sim=1000.
#'
#' @examples
#' # Import or simulate the data (simulation is chosen for illustrative purposes):
#' DATA=simtuts(N=50,Harmonics=c(10,30,0), sin.ampl=c(10,10, 0), cos.ampl=c(0,0,0),
#' trend=0,y.sd=3, ti.sd=1)
#' y=DATA$observed$y.obs
#' ti.mu=DATA$observed$ti.obs.tnorm
#' ti.sd= rep(1, length(ti.mu))
#'
#' # (Set parameters and ) run multiple Lomb-Scargle periodograms:
#' TULS=tuls(y=y,ti.mu=ti.mu,ti.sd=ti.sd)       # Optional parameters: ofac, CI, n.sim
#'
#'# Plot the results:
#' plot(TULS)
#'
#'# Obtain list of frequencies for which spectral power exceeds confidence interval prespecified in the tuts_ls class
#' summary(TULS)
#'
#' @references  \url{https://en.wikipedia.org/wiki/Least-squares_spectral_analysis}
#' @seealso \url{http://cran.r-project.org/package=Bchron}
#' @export
# TULS ----------------------------------------------------------------------------------------------
tuls=function(y,ti.mu,ti.sd,...){
  dots = list(...)
  if(missing(...)){ofac=4; CI=0.99;n.sim=1000}

  if(!is.numeric(dots$CI)){
    CI=0.99
  } else{
    CI=dots$CI
    if(CI<0 | CI>1){stop("CI must be between 0 and 1.")}
  }

  if(!is.numeric(dots$ofac)){
    ofac=4
  } else{
    ofac=dots$ofac
    if((round(ofac)==ofac)==FALSE | ofac<1){stop("ofac must be a positive integer.")}
  }

  if(!is.numeric(dots$n.sim)){
    n.sim=1000
  } else{
    n.sim=dots$n.sim
    if (n.sim!=abs(round(n.sim))){stop("n.sim must be a positive integer.")}
  }


  if(length(y)*4!=length(ti.mu)*2+length(ti.sd)*2){stop("Vectors y, ti.mu and ti.sd should be of equal lengths.")}
  if(is.numeric(ti.mu)==FALSE ){stop("y must be a vector of rational numbers.")}
  if(is.numeric(ti.mu)==FALSE | sum((ti.mu)<0)>0 ){stop("ti.mu must be a vector of positive rational numbers.")}
  if(is.numeric(ti.sd)==FALSE | sum((ti.sd)<0)>0 ){stop("ti.sd must be a vector of positive rational numbers.")}

  alpha=1-CI
# Order observations --------------------------------------------------------------
  y=y[order(ti.mu,decreasing = FALSE)];ti.sd=ti.sd[order(ti.mu,decreasing = FALSE)];
  ti.mu=ti.mu[order(ti.mu,decreasing = FALSE)]
# Apply Lomb-Scargle and simulate -------------------------------------------------
  LSP=lsp(y,ti.mu,ofac=ofac,plot=FALSE,alpha=alpha)
  N=LSP$n.out
  PWR=FRQ=array(NA,dim=c(N,n.sim))
  SIG=rep(NA,n.sim)
  for (i in 1:n.sim){
    ti.sim=sort(rnorm(length(ti.mu), mean=ti.mu,sd=ti.sd))
    LSP=lsp(y,ti.sim,ofac=ofac,plot=FALSE,alpha=alpha)
    PWR[1:N,i]=LSP$power[1:N]
    FRQ[1:N,i]=LSP$scanned[1:N]
    SIG[i]=LSP$sig.level
  }
  # Replace NAs with the last observation
  for(i in (N-5):(N)){
    for(j in 1:n.sim){
      if (is.na(FRQ[i,j])){
        FRQ[i,j]=FRQ[i-1,j]
        PWR[i,j]=PWR[i-1,j]
      }
    }
  }
  # Generate outut ------------------------------------------------------------------
  output = list(Freq=FRQ,Power=PWR,Significance=SIG,CI=CI)
  class(output) = 'tuts_ls'
  plot(output)
  return(output)
}

#' Plot of spectral densities of tuts_LS objects.
#'
#' \code{plot.tuts_LS} Plots a tuts_LS object
#'
#' @param x A tuts_LS obect.
#'
#'
#' @examples
#' # Simulate time-uncertain time series:
#' DATA=simtuts(N=100,Harmonics=c(10,30,0), sin.ampl=c(10,10, 0), cos.ampl=c(0,0,0),
#' trend=0,y.sd=3, ti.sd=1)
#'
#' # (Set parameters and ) run multiple Lomb-Scargle periodograms:
#' TULS=tuls(y=y,ti.mu=ti.mu,ti.sd=ti.sd)       # This funclion also plots spectral densities.
#'                                              # Optional parameters: ofac, CI, n.sim.
#'
#'# Plot the results:
#' plot(TULS)
#'
#' @export
plot.tuts_ls = function(x) {
  par(mfrow=c(1,1))
  plot(x[[1]][,1],x[[2]][,1],type='l',ylim=c(0,max(x[[2]])),xlab='frequency',ylab='normalised power',
       main=paste('Lomb-Scargle Periodogram \n (number of ti realizations = ',toString(dim(x[[2]])[2]),')',sep='')
       )
  lines(x[[1]][,1],   rep(mean(x$Significance),length(x[[1]][,1])), type='l',lty=2)
  for (i in 2:dim(x[[2]])[2]){
    lines(x[[1]][,i],x[[2]][,i],type='l')
  }
  legend("topright",legend = c("Power",paste("Signifficance level at CI=",x$CI*100,"%",sep="")),
         col=c("black","blue"),lwd=c(1,1),lty=c(1,2))
}


#' Function returning a list of frequencies having significant power estimates.
#'
#' \code{summary.tuts_LS} Function returning a list of frequencies for which spectral power exceeds prespecified
#'  confidence interval contained in tuts_LS objects.
#'
#' @param x A tuts_LS obect.
#'
#' @examples
#' # Simulate time-uncertain time series:
#' DATA=simtuts(N=100,Harmonics=c(10,30,0), sin.ampl=c(10,10, 0), cos.ampl=c(0,0,0),
#' trend=0,y.sd=3, ti.sd=1)
#'
#' # (Set parameters and ) run multiple Lomb-Scargle periodograms:
#' TULS=tuls(y=y,ti.mu=ti.mu,ti.sd=ti.sd)       # Optional parameters: ofac, CI, n.sim.
#'
#'# Obtain list of frequencies for which spectral power exceeds prespecified confidence interval
#' summary(TULS)
#' @export

summary.tuts_ls = function(x) {
  FRQ=apply(x$Freq,1,mean)[apply(x$Power,1,max)>mean(x$Significance)]
  return(frequencies=FRQ)
}