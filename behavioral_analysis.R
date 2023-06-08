# Behavioral analysis for the AX-CPT E-Prime log files
# Author: Benjamin Berkhout
library(plyr)
library(dplyr)

data_dir <- "C:/Benjamin/School/FYRP/data"
conditions <- c("LTA", "MTA", "HTA")

lta_files <- list.files(paste0(data_dir, "/LTA"), pattern="*/*.xlsx", recursive = T)
mta_files <- list.files(paste0(data_dir, "/MTA"), pattern="*/*.xlsx", recursive = T)
hta_files <- list.files(paste0(data_dir, "/HTA"), pattern="*/*.xlsx", recursive = T)


# Aggregate all anxiety groups into one df
cond_aggr <- data.frame()
cond_aggr <- aggr_dat(lta_files, "LTA", cond_aggr)
cond_aggr <- aggr_dat(mta_files, "MTA", cond_aggr)
cond_aggr <- aggr_dat(hta_files, "HTA", cond_aggr)

cond_aggr$cond <- factor(cond_aggr$cond, levels=c("LTA", "MTA", "HTA"))
cond_aggr$pair <- paste0(cond_aggr$cue, cond_aggr$probe)

# Do some anova tests

aov_LTA_HTA <- aov(ACC ~ cond,data=cond_aggr[cond_aggr$pair == "BX" & cond_aggr$cond %in% c("LTA", "HTA"),])
summary(aov_LTA_HTA)

aov_probes <- aov(ACC ~ pair, data=cond_aggr[cond_aggr$pair %in% c("BX", "AY"),])
summary(aov_probes)

means <- ddply(cond_aggr, c("pair", "cond"), summarise,
      acc = round(mean(ACC), 2))
t(means)

# Create boxplots of RT and ACC across conditions

boxplot(ACC ~ cond ,data=cond_aggr[cond_aggr$pair == "BX",], col=c("chartreuse", "brown1", "cornflowerblue"),
        xlab="Condition", main="Average accuracy for BX pair")
boxplot(RT ~ cond ,data=cond_aggr[cond_aggr$pair == "BX",], col=c("chartreuse", "brown1", "cornflowerblue"),
        xlab="Condition", main="Average RT for BX pair")

boxplot(ACC ~ cond ,data=cond_aggr[cond_aggr$pair == "AX",],  col=c("chartreuse", "brown1", "cornflowerblue"),
        xlab="Condition", main="Average accuracy for AX pair")
boxplot(RT ~ cond ,data=cond_aggr[cond_aggr$pair == "AX",], col=c("chartreuse", "brown1", "cornflowerblue"),
        xlab="Condition", main="Average RT for AX pair")

boxplot(ACC ~ cond ,data=cond_aggr[cond_aggr$pair == "AY",],  col=c("chartreuse", "brown1", "cornflowerblue"), 
        xlab="Condition", main="Average accuracy for AY pair")
boxplot(RT ~ cond ,data=cond_aggr[cond_aggr$pair == "AY",], col=c("chartreuse", "brown1", "cornflowerblue"),
        xlab="Condition", main="Average RT for AY pair")

boxplot(ACC ~ cond ,data=cond_aggr[cond_aggr$pair == "BY",], col=c("chartreuse", "brown1", "cornflowerblue"),
        xlab="Condition", main="Average accuracy for BY pair")


# Function to add all files in directory to one df
aggr_dat <- function (files, condition, aggreted_dat){
  
  total_trial_rm <- 0
  
  for (file in files){
    dat <- read_excel(paste0(data_dir, "/",condition, "/", file))
    subj_name <- strsplit(file, "/")[[1]][2]
    print(nrow(dat))
    
    # Remove subject if less than 60% accuracy on BY trials
    BY_acc <- mean(dat[dat$cue == "B" & dat$probe == "Y",]$probe.ACC)
    if (BY_acc < 0.6) {
      print(paste0("Subject removed: ", subj_name))
      next
    }
    
    # Remove trials if RT is more than 3 SD from the mean
    correct_dat <- dat[dat$probe.ACC == 1,]
    lower_threshold <- mean(correct_dat$probe.RT) - 3*sd(correct_dat$probe.RT)
    upper_threshold <- mean(correct_dat$probe.RT) + 3*sd(correct_dat$probe.RT)
    
    total_trial_rm <- total_trial_rm + sum(dat$probe.RT < threshold)
    dat <- dat[dat$probe.RT > lower_threshold & dat$probe.RT < upper_threshold,]
    
    # Average trials
    subj_aggr <- ddply(dat, c("cue", "probe", "Subject"), summarise,
          ACC = mean(probe.ACC),
          RT = mean(probe.RT)
          )
    subj_aggr$cond <- condition
    subj_aggr$meanRT = mean(subj_aggr$ACC)
    aggreted_dat <- rbind(aggreted_dat, subj_aggr)
  }
  print(total_trial_rm)
  return (aggreted_dat)
}


