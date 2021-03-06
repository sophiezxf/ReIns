
# Tests to see if vectorised versions give same result as slower for-loops
context("Vectorisation")

eps <- sqrt(.Machine$double.eps)

data(secura)
X <- sort(secura$size)
n <- length(X)
censored <- sample(c(0,1),length(secura$size),replace=TRUE)

##############################################
# Censoring.R

test_that("Censored estimators for-loops", {
  
  
  ###################################################
  # cHill
  
  delta <- !censored
  # Slow for-loop
  Hill2 <- numeric(n-1)
  for (k in 1:(n-1)) {
	  if (sum(delta[n-(1:k)+1])!=0) {
	    Hill2[k] <- (1/sum(delta[n-(1:k)+1]))*sum(log(X[n-(1:k)+1])-log(X[n-k])) 
	  } else {
	    Hill2[k] <- NA
	  }
	}

  
  expect_true(max(abs(cHill(X,censored=censored)$gamma-Hill2)/Hill2,
                  na.rm=TRUE)<eps)
  
  ######################
  # cgenHill
  
  UH.scores2 <- numeric(n)
  Hill2 <- numeric(max((n-2),1))
  gamma <- cHill(X,censored=censored)$gamma
  # Slow for-loops
  UH.scores2 <- numeric(n)
	Hill2 <- numeric(max((n-2),1))
	for (i in 1:(n-1)) {
    if (sum(delta[n-(1:i)+1])!=0) {
	    UH.scores2[i] <- X[n-i]*gamma[i]
    } else{
      UH.scores2[i] <- 1
    }
	}	
	
	for (k in 1:max((n-2),1)) {
    if (sum(delta[n-(1:k)+1])!=0) {
      Hill2[k] <- sum(log(UH.scores2[1:k])-log(UH.scores2[k+1]))/sum(delta[n-(1:k)+1])
    } else {
      Hill2[k] <- NA
    }
	  
	}

  
  expect_true(max(abs(cgenHill(X,censored=censored)$gamma-Hill2)/Hill2,
                  na.rm=TRUE)<eps)
	
	######################
	# cParetoQQ
	
	  
  pqq.the3 <- numeric(n-1)
  for (j in 1:(n-1)) { 
    pqq.the3[j] <- -log(KaplanMeier(X[n-j+1],X,censored)$surv)
  }
  
  expect_true(max(abs(cParetoQQ(X,censored=censored,plot=FALSE)$pqq.the- pqq.the3 )/ pqq.the3 ,
                  na.rm=TRUE)<eps)
  
	  

  ################################
  # p_hat_fun
  
  delta.n <- delta
  p.hat <- numeric(n-1)
  for (k in 1:(n-1)) {
    p.hat[k] <- mean(delta.n[n:(n-k+1)])
  }
  
  
  expect_true(max(abs(p.hat - .p_hat_fun(delta.n))/ p.hat,
                  na.rm=TRUE)<eps)

})


##############################################
# Hill.R

test_that("Hill for-loop", {
  
  # Hill
  Hill2 <- numeric(n-1)
	for (k in 1:(n-1)) {
	  Hill2[k] <- (1/k)*sum(log(X[n:(n-k+1)])) - log(X[n-k])
	}

  expect_true(max(abs(Hill(X)$gamma-Hill2)/Hill2,na.rm=TRUE)<eps)
  
  ######################
  # genHill
	UH.scores2 <- numeric(n)
	Hill2 <- numeric(max((n-2),1))
	gamma = Hill(X)$gamma
	for (i in 1:(n-1)) {
	  UH.scores2[i] <- X[n-i]*gamma[i]
	}	
	
	for (k in 1:max((n-2),1)) {
	  Hill2[k] <- sum(log(UH.scores2[1:k])-log(UH.scores2[k+1]))/k
	}
	expect_true(max(abs(genHill(X,gamma=gamma)$gamma-Hill2)/Hill2,na.rm=TRUE)<eps)
})


##############################################
# LStail.R

test_that("LStail for-loop", {
  
  rho <- -1
  par2 <- matrix(nrow=n-1,ncol=3)
  par2[,3] <- rho
  
  UH.scores <- numeric(n)
  K <- 1:(n-1)
  UH.scores[K] <- X[n-K] * Hill(X)$gamma[K]
  
  
  # Obtain LS estimators for gamma and b using full model Z_j = gamma + b*(j/k)^(-rho) + eps_j
  for (k in (n-1):1) {
    Z <- ((1:k)+1)*log(UH.scores[(1:k)]/UH.scores[(1:k)+1])
    par2[k,2] <- ((1-par2[k,3])^2*(1-2*par2[k,3])/par2[k,3]^2)*sum((((1:k)/k)^(-par2[k,3])-1/(1-par2[k,3]))*Z)/k
    par2[k,1] <- sum(Z)/k-par2[k,2]/(1-par2[k,3])
  }
  
  
  res <- LStail(X,rho=rho)
  expect_true(max(abs(res$gamma-par2[,1])/par2[,1],na.rm=TRUE)<eps)
  expect_true(max(abs(res$b-par2[,2])/par2[,2],na.rm=TRUE)<eps)
  
  
  
  ###################################################################
  # Test with rho a vector
  
  res <- LStail(X,rho=NULL)
  
  par2 <- matrix(nrow=n-1,ncol=3)
  par2[,3] <- res$rho
  
  UH.scores <- numeric(n)
  K <- 1:(n-1)
  UH.scores[K] <- X[n-K] * Hill(X)$gamma[K]
  
  
  # Obtain LS estimators for gamma and b using full model Z_j = gamma + b*(j/k)^(-rho) + eps_j
  for (k in (n-1):1) {
    Z <- ((1:k)+1)*log(UH.scores[(1:k)]/UH.scores[(1:k)+1])
    par2[k,2] <- ((1-par2[k,3])^2*(1-2*par2[k,3])/par2[k,3]^2)*sum((((1:k)/k)^(-par2[k,3])-1/(1-par2[k,3]))*Z)/k
    par2[k,1] <- sum(Z)/k-par2[k,2]/(1-par2[k,3])
  }
  
  expect_true(max(abs(res$gamma-par2[,1])/par2[,1],na.rm=TRUE)<eps)
  expect_true(max(abs(res$b-par2[,2])/par2[,2],na.rm=TRUE)<eps)
  
})


##############################################
# Moment.R

test_that("Moment for-loop", {
  
  M12 <- numeric(n-1)
  M22 <- numeric(n-1)
  
  for (k in (n-1):1) {
    Z.values <- log(X[n:(n-k+1)]/X[n-k])
    M12[k] <- (1/k)*sum(Z.values)
    M22[k] <- (1/k)*sum(Z.values^2)
  }
  
  Mom2 <- M12 + 1 - (1-M12^2/M22)^(-1)/2
  
  expect_true(max(abs(Moment(X)$gamma[-1]-Mom2[-1])/Mom2[-1],na.rm=TRUE)<eps)
})

##############################################
# QQplots.R

test_that("MeanExcess for-loop", {
  # Slow for-loop
  e2 <- numeric(n-1)
  for (kk in 1:(n-1)) {
    e2[kk] <- sum(X[n-(1:kk)+1])/kk-X[n-kk] 
  }
  e <- MeanExcess(X,plot=FALSE)$e
  
  expect_true(max(abs(e-e2)/e2,na.rm=TRUE)<eps)
})



##############################################
# Truncated estimators

test_that("Truncation (gamma pos) for-loops", {

  
  r <- 4
  
  
  # tr.gamma.pos
  
  H_for <- H1_for <- numeric(n-1)
  for (k in (n-1):r) {
    Z.values <- log(X[(n-r+1):(n-k+1)]/X[n-k])
    Z1.values <- log(X[n:(n-k+1)]/X[n-k])
    H_for[k] <- (1/(k-r+1))*sum(Z.values)
   
  }
  
  expect_true(max(abs(trHill(X,r=r)$H-H_for[r:(n-1)])/H_for[r:(n-1)],na.rm=TRUE)<eps)
  
  
  # tr.DT.pos
  
  K <- r:(n-1)
  DT <- numeric(n)
  R <- numeric(n)
  A <- numeric(n)
  
  gamma <- trHill(X,r=r)$gamma
  gamma <- abs(gamma)
  A[K] <- 1/gamma


  R[K] <- X[n-K]/X[n-r+1]
  for (k in (n-1):r) {
    DT[k] <- max(((k+1)/(n+1))*(R[k]^A[k]-r/(k+1))/(1-R[k]^A[k]),0)
  }
  
  expect_true(max(abs(trDT(X,gamma=gamma,r=r)$DT-DT[K]),na.rm=TRUE)<eps)
  
  
  # tr.Tk.pos
  
  K <- r:(n-1)
  Tk <- numeric(n)
  R <- numeric(n)
  G <- numeric(n)
  
  gamma <- trHill(X,r=r)$gamma
  G[K] <- abs(gamma)
  
  R[K] <- X[n-K] / X[n]
  
  for (k in (n-1):r) {
    Tk[k] <- max(X[n-k] * ((R[k]^(1/G[k])-1/(k+1)) / (1-1/(k+1)))^(-G[k]), X[n])
  }
  
  expect_true(max(abs(trEndpoint(X,gamma=gamma,r=r)$Tk-Tk[K]),na.rm=TRUE)<eps)
  
  
  
  # tr.quant.pos
  
  
  p <- 0.01
  
  K <- r:(n-1)
  quant <- numeric(n)
  R <- numeric(n)
  A <- numeric(n)
  Dt <- numeric(n)
  
  gamma <- trHill(X,r=r)$gamma
  gamma <- abs(gamma)
  
  DT <- trDT(X,gamma=gamma,r=r)$DT
  Dt[K] <- DT
  A[K] <- 1/gamma
  
    
  for (k in (n-1):r) {
    quant[k] <- X[n-k]*((Dt[k]+(k+1)/(n+1))/(Dt[k]+p))^(1/A[k])
  }
  

  expect_true(max(abs(trQuant(X,p=p,gamma=gamma,DT=DT,r=r)$Q-quant[K]),na.rm=TRUE)<eps)
  
  ##############
  # Test for truncation
  
  K <- 1:(n-1)
  
  H <- Hill(X)$gamma
  
  # Compute L(H_{k,n})
  E <- numeric(n)

  for (k in K) {
    E[k] <- 1/k * sum((X[n-k]/X[n-(1:k)+1])^(1/H[k]))
  }  
  
  L <- (E[K]-0.5)/(1-E[K])
  
  #Test value
  tv <- sqrt(12*K)*L
  
  
  expect_true(max(abs(trTest(X,plot=FALSE)$testVal-tv[K]),na.rm=TRUE)<eps)
  
})


########################################
# crHill


# Set seed
set.seed(29072016)

# Pareto random sample
Y <- rpareto(100, shape=2)

# Censoring variable
C <- rpareto(100, shape=1)

# Observed (censored) sample of variable Y
Ytilde <- pmin(Y, C)

# Censoring indicator
censored <- (Y>C)

# Conditioning variable
X <- seq(1, 10, length.out=length(Y))

# Observed (censored) sample of conditioning variable
Xtilde <- X
Xtilde[censored] <- X[censored] - runif (sum(censored), 0, 1)

# Bandwidth
h <- 5

# Kernel
Kernel = "biweight"

# Value of covariate
x <- 2

test_that("crHill for-loop", {
  
  ###
  # Slower old function
  
  n <- length(Xtilde)
  kernel <- .kernel_aux(Kernel, h=1)
  
  # Convert censored to Delta
  Delta <- !as.logical(censored)
  
  
  # Sort data according to Ytilde values
  s <- sort(Ytilde, index.return=TRUE)
  Ytilde_sort <- s$x
  Xtilde_sort <- Xtilde[s$ix]
  Delta_sort <- Delta[s$ix]
  
  # Nadaraya weights, only non-zero when uncensored
  # Sorted with Ytilde!
  weights_sort <- numeric(n)
  weights_sort[Delta_sort] <- kernel((x-Xtilde_sort[Delta_sort])/h)
  weights_sort <- weights_sort / sum(weights_sort)
  
  K <- 1:(n-1)
  H2 <- numeric(n-1)
  
  # Compute cumulative sum of weights,
  # add 0 to avoid problems when ind is empty
  wsum <- c(0, cumsum(weights_sort))
  
  # Avoid numerical problems
  wsum[wsum==1] <- wsum[wsum==1] - 10^(-16)
  
  for (k in 1:(n-1)) {
    
    prods <- numeric(k)
    
    # Compute products for i=1,...,k
    for (i in 1:k) {
      ind <- 1:(n-i)
      # Note that wsum[1]=0 !
      prods[i] <- prod((1 - weights_sort[ind] / (1-wsum[ind]))^Delta_sort[ind])
    }
    H2[k] <- sum(prods * (log(Ytilde_sort[n-(1:k)+1])-log(Ytilde_sort[n-(1:k)]))) / prods[k]
  }
  
  ###
  # Faster new version
  H <- crHill(x=x, Xtilde=Xtilde, Ytilde=Ytilde, censored=censored, h=h, kernel=Kernel)$gamma
  
  expect_true(max(abs(H-H2)/H2,na.rm=TRUE)<eps)
})


