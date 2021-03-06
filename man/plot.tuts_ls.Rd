% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/a_tuls.r
\name{plot.tuts_ls}
\alias{plot.tuts_ls}
\title{Plot of spectral densities of tuts_LS objects.}
\usage{
\method{plot}{tuts_ls}(x)
}
\arguments{
\item{x}{A tuts_LS obect.}
}
\description{
\code{plot.tuts_LS} Plots a tuts_LS object
}
\examples{
# Simulate time-uncertain time series:
DATA=simtuts(N=100,Harmonics=c(10,30,0), sin.ampl=c(10,10, 0), cos.ampl=c(0,0,0),
trend=0,y.sd=3, ti.sd=1)

# (Set parameters and ) run multiple Lomb-Scargle periodograms:
TULS=tuls(y=y,ti.mu=ti.mu,ti.sd=ti.sd)       # This funclion also plots spectral densities.
                                             # Optional parameters: ofac, CI, n.sim.

# Plot the results:
plot(TULS)

}
