# Quantify the relative influence of each assembly processes
# Date: 15-10-2019
# Author: Jia Xiu

rm(list=ls())

# Load the libraries
library(reshape2) 
library(ggplot2)
library(ggpubr)
library(scales) 
library(dplyr)
library(ggforce)


# load directory -----------------------------------------------------------------------------------------
directory = '~/Dropbox/'
subfolder = 'Schier/cDNA'

setwd(paste(directory, subfolder, sep="/"))
getwd()

##########################################################################################################
# Assembly processes for the whole dataset
##########################################################################################################

# make a matrix to store the number of pairwise samples of each assembly process -------------------------
df <- matrix(NA, nrow = 5, ncol = 3)
row.names(df) <- c("Variable.selection", "Homogeneous.selection", 
                   "Dispersal.limitation", "Homogenizing.dispersal", "Undominated.processes")
colnames(df) <- c("Whole", "Dominant", "Rare")
df

# set parameters -----------------------------------------------------------------------------------------
cutoff = 0.1/100
iteration = 999

# all three data sets
data.set.names = c('wholeDS', 'truncated_ds_dominant', 'truncated_ds_rare_without_dominant')

# a loop to calculte for the assembly processes of each rarity/commonnness type
for (xx in data.set.names) {
  data.set.name = xx
  
  # Quantify each assembly process -----------------------------------------------------------------------
  if (data.set.name == 'wholeDS') {
    nti <- read.csv(paste(data.set.name, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE) 
    rc <- read.csv(paste("RC-bray", data.set.name, iteration, ".csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  } 
  else if (data.set.name == 'truncated_ds_dominant') { 
    nti <- read.csv(paste(data.set.name, cutoff, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE)
    rc <- read.csv(paste("RC-bray", data.set.name, cutoff, "999.csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  } 
  else if (data.set.name == 'truncated_ds_rare_without_dominant') {
    nti <- read.csv(paste(data.set.name, cutoff, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE)
    rc <- read.csv(paste("RC-bray", data.set.name, cutoff, "999.csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  }
  
  # read weighted beta NTI -------------------------------------------------------------------------------
  colnames(nti) <- sub("cDNA_", "", colnames(nti))
  row.names(nti) <- sub("cDNA_", "", row.names(nti))
  nti <- as.matrix(nti)
  # Function to extract pairwise value from a n*n lower trianglar matrix
  nti <- data.frame(as.table(nti))[lower.tri(nti, diag = FALSE), ]
  cat("should got:", (60*60-60)/2, "pair-wise distance\n"); 
  cat("Actually we got:", length(nti$Freq), "pair-wise distance\n")
  cat("the mean beta-NTI is:", round(mean(na.omit(nti$Freq)),2), "\n")
  row.names(nti) <- paste(nti$Var1, nti$Var2, sep = "_")
  head(nti)
  str(nti)
  
  # RC-bray -----------------------------------------------------------------------------------------------
  colnames(rc) <- sub("cDNA_", "", colnames(rc))
  row.names(rc) <- sub("cDNA_", "", row.names(rc))
  rc <- as.matrix(rc)
  rc <- data.frame(as.table(rc))[lower.tri(rc, diag = FALSE), ]
  cat("should got:", (60*60-60)/2, "pair-wise distance\n"); 
  cat("Actually we got:", length(rc$Freq), "pair-wise distance\n")
  cat("the mean RC-bray is:", round(mean(na.omit(rc$Freq)),2), "\n")
  row.names(rc) <- paste(rc$Var1, rc$Var2, sep = "_")
  head(rc)
  str(rc)
  
  
  # Combine the beta-NTI values with RC-bray
  nti.rc <- merge(nti, rc, by=0, all=TRUE)  # merge by row names (by=0 or by="row.names")
  nti.rc <- data.frame(nti = nti.rc$Freq.x, rc = nti.rc$Freq.y, row.names = nti.rc$Row.names)
  
  # Invalid the value of RC-bray in which the beta-NTI larger than +2 or less than -2
  for (i in 1:nrow(nti.rc)) {
    if (nti.rc[i,1] > 2 | nti.rc[i,1] < -2) {
      nti.rc[i, 2] <- NA
    }
  }
  
  head(nti.rc)
  str(nti.rc)
  
  # Quantify each assembly process ------------------------------------------------------------------------
  if (data.set.name == 'wholeDS') {
    i = 1 } else if (data.set.name == 'truncated_ds_dominant') { 
      i = 2 } else if (data.set.name == 'truncated_ds_rare_without_dominant') {
        i = 3
      }
  
  # Variable selection
  Variable.selection <- nti.rc$nti > 2
  cat('Number of variable  selection:', table(Variable.selection)['TRUE'], 'within', nrow(nti.rc), 'pairwise samples\n')
  df[1, i] <- length(Variable.selection[Variable.selection == TRUE])
  
  # Homogenous selction
  Homogeneous.selection <- nti.rc$nti < -2
  cat('Number of homogenous selection:', table(Homogeneous.selection)['TRUE'], 'within', nrow(nti.rc), 'pairwise samples\n')
  df[2, i] <- table(Homogeneous.selection)['TRUE']#length(c[Homogeneous.selection == TRUE])
  
  # Dispersal limilation
  Dispersal.limilation <- na.omit(nti.rc$rc) > 0.95
  cat('Number of dispersal limitation:', table(Dispersal.limilation)['TRUE'], 'within', nrow(nti.rc), 'pairwise samples\n')
  df[3, i] <- length(Dispersal.limilation[Dispersal.limilation == TRUE])
  
  # Homogenizing dispersal
  Homogenizing.dispersal <- na.omit(nti.rc$rc) < -0.95
  cat('Number of homogenizing dispersal:', table(Homogenizing.dispersal)['TRUE'], 'within', nrow(nti.rc), 'pairwise samples\n')
  df[4, i] <- length(Homogenizing.dispersal[Homogenizing.dispersal == TRUE])
  
  # Undominated processes
  Undominated.processes <- na.omit(nti.rc$rc) <= 0.95 & na.omit(nti.rc$rc) >= -0.95
  cat('Number of Undominated processes:', table(Undominated.processes)['TRUE'], 'within', nrow(nti.rc), 'pairwise samples\n')
  df[5, i] <- length(Undominated.processes[Undominated.processes == TRUE])
}

# calculate relatice impacts of each process --------------------------------------------------------------------------
df1 <- melt(df)
df1$value <- round(df1$value*100/nrow(nti.rc), 2)
colnames(df1) <- c("Processes", "groups", "value")

df1$Processes <- factor(df1$Processes, levels = c('Variable.selection', 'Homogeneous.selection', 'Dispersal.limitation', 
                                                  'Homogenizing.dispersal', 'Undominated.processes'),
                        labels = c('Variable selection', 'Homogeneous selection', 'Dispersal limilation', 
                                   'Homogenizing dispersal', 'Undominated processes'))
df1$groups <- factor(df1$groups, levels = c('Whole', 'Dominant', 'Rare'), 
                     labels = c('Whole community', 'Common biosphere', 'Rare biosphere'))

df1

# pie plot (clockwise) ---------------------------------------------------------------------------------
df1[df1 == 0] <- NA
df1 <- na.omit(df1)

# calculate the start and end angles for each pie
dat_pies <- left_join(df1,
                      df1 %>% 
                        group_by(groups) %>%
                        summarize(value_total = sum(value))) %>%
  group_by(groups) %>%
  mutate(end_angle = 2*pi*cumsum(value)/value_total,      # ending angle for each pie slice
         start_angle = lag(end_angle, default = 0),   # starting angle for each pie slice
         mid_angle = 0.5*(start_angle + end_angle))   # middle of each pie slice, for the text label

rpie = 1 # pie radius
rlabel = 0.6 * rpie # radius of the labels; a number slightly larger than 0.5 seems to work better, 0.5 would place it exactly in the middle as the question asks for.

# draw the pies
pie <- ggplot(dat_pies) + 
  geom_arc_bar(aes(x0 = 0, y0 = 0, r0 = 0, r = rpie, start = start_angle, end = end_angle, fill = Processes)) +
  geom_text(aes(x = rlabel*sin(mid_angle), y = rlabel*cos(mid_angle), label = paste(round(value,2), "%")), 
            hjust = 0.5, vjust = 0.5, size=4) +
  coord_fixed() +
  scale_x_continuous(limits = c(-1, 1), name = "", breaks = NULL, labels = NULL) +
  scale_y_continuous(limits = c(-1, 1), name = "", breaks = NULL, labels = NULL) +
  facet_grid(.~groups)+
  scale_fill_manual(values = c("#00A087B2","#FFDB6D", "#DC0000B2", "#4DBBD5B2", "#7570B3")) +
  theme_minimal()+
  theme(legend.title=element_text(size=13),
        text = element_text(size=15),
        axis.text.x=element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.ticks = element_blank())
pie


# pie plot (Anti-clockwise)
pie2 <- ggplot(df1, aes(x="", y=value, fill=Processes))+
  geom_bar(stat="identity", width=1, colour = "black") +
  facet_grid(facets=. ~ groups)+
  coord_polar("y", start=0)+
  scale_fill_manual(values = c("#00A087B2","#FFDB6D", "#DC0000B2", "#4DBBD5B2", "#7570B3")) +
  geom_text(aes(label = paste0(round(value, 2), "%")), position = position_stack(vjust = 0.5))+
  theme_minimal()+
  theme(text = element_text(size=14),
        axis.text.x=element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.ticks = element_blank(),
        plot.title=element_text(size=15, face="bold"))
pie2

##########################################################################################################
# Year and Month
##########################################################################################################

# Year ---------------------------------------------------------------------------------------------------

datalist <- list()

# all three data sets
data.set.names = c('wholeDS', 'truncated_ds_dominant', 'truncated_ds_rare_without_dominant')

# a loop to calculte for the assembly processes of each rarity/commonnness type
for (xx in data.set.names) {
  data.set.name = xx
  
  # Quantify each assembly process ------------------------------------------------------------------------
  if (data.set.name == 'wholeDS') {
    nti <- read.csv(paste(data.set.name, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE) 
    rc <- read.csv(paste("RC-bray", data.set.name, iteration, ".csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  } 
  else if (data.set.name == 'truncated_ds_dominant') { 
    nti <- read.csv(paste(data.set.name, cutoff, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE)
    rc <- read.csv(paste("RC-bray", data.set.name, cutoff, "999.csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  } 
  else if (data.set.name == 'truncated_ds_rare_without_dominant') {
    nti <- read.csv(paste(data.set.name, cutoff, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE)
    rc <- read.csv(paste("RC-bray", data.set.name, cutoff, "999.csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  }
  
  cat("\ncalcultate asssembly processes for", data.set.name, "\n")
  # read weighted beta NTI and RC-bray matrix ------------------------------------------------------------------------------------
  # read weighted beta NTI matrix
  colnames(nti) <- sub("cDNA_", "", colnames(nti))
  row.names(nti) <- sub("cDNA_", "", row.names(nti))
  nti <- as.matrix(nti)
  # extract pairwise value from a n*n lower trianglar matrix
  nti <- data.frame(as.table(nti))[lower.tri(nti, diag = FALSE), ]
  cat("\n>>> for dataset:", data.set.name,
      "\nshould got:", (60*60-60)/2, "pair-wise beta-NTI", 
      "\nActually we got:", length(nti$Freq), "pair-wise distance", 
      "\nthe mean beta-NTI is:", round(mean(na.omit(nti$Freq)),2))
  row.names(nti) <- paste(nti$Var1, nti$Var2, sep = "_")
  group <- data.frame(row.names=rownames(nti), t(as.data.frame(strsplit(as.character(row.names(nti)), "_"))))
  nti <- data.frame(row.names = rownames(nti), X1 = group$X1, X4 = group$X4, Freq = nti$Freq)
  nti <- nti[which(nti$X1==nti$X4),]
  head(nti)
  str(nti)
  
  # Read Roup Crick - bray matrix
  colnames(rc) <- sub("cDNA_", "", colnames(rc))
  row.names(rc) <- sub("cDNA_", "", row.names(rc))
  rc <- as.matrix(rc)
  rc <- data.frame(as.table(rc))[lower.tri(rc, diag = FALSE), ]
  cat("\n>>> for dataset:", data.set.name,
      "\nshould got:", (60*60-60)/2, "pair-wise beta-NTI", 
      "\nActually we got:", length(rc$Freq), "pair-wise distance", 
      "\nthe mean beta-NTI is:", round(mean(na.omit(rc$Freq)),2))
  
  row.names(rc) <- paste(rc$Var1, rc$Var2, sep = "_")
  group <- data.frame(row.names=rownames(rc), t(as.data.frame(strsplit(as.character(row.names(rc)), "_"))))
  rc <- data.frame(row.names = rownames(rc), X1 = group$X1, X4 = group$X4, Freq = rc$Freq)
  rc <- rc[which(rc$X1==rc$X4),]
  head(rc)
  str(rc)
  
  # Combine the beta-NTI with RC-bray
  nti.rc <- merge(nti, rc, by=0, all=TRUE)  # merge by="row.names"
  nti.rc <- data.frame(Year = nti.rc$X1.x, nti = nti.rc$Freq.x, rc = nti.rc$Freq.y, row.names = nti.rc$Row.names)
  
  # Invalid the value of RC-bray in which the beta-NTI larger than +2 or less than -2
  for (i in 1:nrow(nti.rc)) {
    if (nti.rc[i,2] > 2 | nti.rc[i,2] < -2) {
      nti.rc[i,3] <- NA
    }
  }
  
  nti.rc$Year <- factor(nti.rc$Year, levels=c("0", "10", "40", "70", "110"))
  head(nti.rc)
  str(nti.rc)
  
  # calculate the relative influence of each assembly processes for each successional stage -----
  # make a matrix to store the number of pairwise samples of each assembly process
  df <- matrix(NA, nrow = 5, ncol = 6)
  df[, 1] <- c("0", "10", "40", "70", "110")
  colnames(df) <- c("Year", "Variable.selection", "Homogeneous.selection", 
                    "Dispersal.limitation", "Homogenizing.dispersal", "Undominated.processes")
  
  for (year in levels(nti.rc$Year) ) {
    
    cat("\nfor", year, "years :\n")
    # Variable selection
    Variable.selection <- nti.rc[nti.rc$Year == year, ]$nti > 2
    cat("Number of variable  selection :",  table(Variable.selection)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Year == year, ]), "pairwise samples\n")
    df[df[,1] == year, 2] <- length(Variable.selection[Variable.selection == TRUE])
    
    # Homogeneous selction
    Homogeneous.selection <- nti.rc[nti.rc$Year == year, ]$nti < -2
    cat("Number of Homogeneous selection is:", table(Homogeneous.selection)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Year == year, ]), "pairwise samples\n")
    df[df[,1] == year, 3] <-  length(Homogeneous.selection[Homogeneous.selection == TRUE]) # table(Homogeneous.selection)["TRUE"] #
    
    # Dispersal limilation
    Dispersal.limilation <- na.omit(nti.rc[nti.rc$Year == year, ]$rc) > 0.95
    cat("Number of dispersal limitation is:", table(Dispersal.limilation)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Year == year, ]), "pairwise samples\n")
    df[df[,1] == year, 4] <- length(Dispersal.limilation[Dispersal.limilation == TRUE])
    
    # Homogenizing dispersal
    Homogenizing.dispersal <- na.omit(nti.rc[nti.rc$Year == year, ]$rc) < -0.95
    cat("Number of homogenizing dispersal is:", table(Homogenizing.dispersal)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Year == year, ]), "pairwise samples\n")
    df[df[,1] == year, 5] <- length(Homogenizing.dispersal[Homogenizing.dispersal == TRUE])
    
    # Undominated processes
    Undominated.processes <- na.omit(nti.rc[nti.rc$Year == year, ]$rc) <= 0.95 & 
      na.omit(nti.rc[nti.rc$Year == year, ]$rc) >= -0.95
    cat("Number of Undominated processes is:", table(Undominated.processes)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Year == year, ]), "pairwise samples\n")
    df[df[,1] == year, 6] <- length(Undominated.processes[Undominated.processes == TRUE])
  }
  datalist[[xx]] <- df
}

str(datalist)
df <- do.call(rbind.data.frame, datalist)
df$fraction <- gsub(".{2}$", "", row.names(df))

df1 <- melt(df, id=c("fraction", "Year"))
df1[is.na(df1)] <- 0
df1$value <- as.numeric(df1$value)
cat("should get", 66*5*3, "pairwise comparision index,\nactually got", sum(df1$value), "pairwise comparision index")

df1$value <- round(df1$value*100/66, 2)
df1[,4][df1[,4] == 0] <- NA; df1 <- na.omit(df1)

df1$fraction <- factor(df1$fraction, levels = c("wholeDS", "truncated_ds_dominant", "truncated_ds_rare_without_dominant"), 
                       labels = c("Whole community", "Common biosphere", "Rare biosphere"))

df1$Processes <- factor(df1$variable, levels = c("Variable.selection", "Homogeneous.selection", "Dispersal.limitation", 
                                                 "Homogenizing.dispersal", "Undominated.processes"),
                        labels = c("Variable selection", "Homogeneous selection", "Dispersal limilation", 
                                   "Homogenizing dispersal", "Undominated processes"))

df1$Year <- factor(df1$Year, levels = c("0", "10", "40", "70", "110"))

str(df1)

# theme for stacked-bar plot
mytheme <- theme_bw()+ 
  theme(text = element_text(size = 11),
        strip.background = element_blank(),
        strip.placement = "outside",
        strip.text = element_text(face="bold", size = 11),
        legend.box.background = element_rect(),
        legend.box.margin = margin(1, 1, 1, 1),
        legend.title=element_text(face = "bold", size = 11),
        legend.justification=c(1, 0.8), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

# stacked-bar plot
(f1 <- ggplot(df1, aes(x=Year, y=value, fill=Processes)) + 
    facet_grid(.~fraction) +
    geom_bar(stat="identity", width=0.8, colour = "black") +
    scale_y_continuous(expand = c(0, 0), limits = c(0,105))+
    scale_fill_manual(values = c("#00A087B2","#FFDB6D", "#DC0000B2", "#4DBBD5B2", "#7570B3")) +
    labs(x="Stage of succession (Years)", y="Relative Influence (%)", title="") +
    mytheme)



# Month  --------------------------------------------------------------------------------------------------


datalist <- list()

# all three data sets
data.set.names = c('wholeDS', 'truncated_ds_dominant', 'truncated_ds_rare_without_dominant')

# a loop to calculte for the assembly processes of each rarity/commonnness type
for (xx in data.set.names) {
  data.set.name = xx
  
  # Quantify each assembly process ------------------------------------------------------------------------
  if (data.set.name == 'wholeDS') {
    nti <- read.csv(paste(data.set.name, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE) 
    rc <- read.csv(paste("RC-bray", data.set.name, iteration, ".csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  } 
  else if (data.set.name == 'truncated_ds_dominant') { 
    nti <- read.csv(paste(data.set.name, cutoff, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE)
    rc <- read.csv(paste("RC-bray", data.set.name, cutoff, "999.csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  } 
  else if (data.set.name == 'truncated_ds_rare_without_dominant') {
    nti <- read.csv(paste(data.set.name, cutoff, "weighted_bNTI.csv", sep="_"), 
                    header=1, row.names=1, check.names=FALSE)
    rc <- read.csv(paste("RC-bray", data.set.name, cutoff, "999.csv", sep="_"), 
                   header=1, row.names=1, check.names=FALSE)
  }
  
  cat("\ncalcultate asssembly processes for", data.set.name, "\n")
  
  # read weighted beta NTI and RC-bray matrix ------------------------------------------------------------------------------------
  # read weighted beta NTI matrix
  colnames(nti) <- sub("cDNA_", "", colnames(nti))
  row.names(nti) <- sub("cDNA_", "", row.names(nti))
  nti <- as.matrix(nti)
  # extract pairwise value from a n*n lower trianglar matrix
  nti <- data.frame(as.table(nti))[lower.tri(nti, diag = FALSE), ]
  cat("should got:", (60*60-60)/2, "pair-wise distance\n"); 
  cat("Actually we got:", length(nti$Freq), "pair-wise distance\n")
  cat("the mean beta-NTI is:", round(mean(na.omit(nti$Freq)),2), "\n")
  
  row.names(nti) <- paste(nti$Var1, nti$Var2, sep = "_")
  group <- data.frame(row.names=rownames(nti), t(as.data.frame(strsplit(as.character(row.names(nti)), "_"))))
  nti <- data.frame(row.names = rownames(nti), X2 = group$X2, X5 = group$X5, Freq = nti$Freq)
  nti <- nti[which(nti$X2==nti$X5),]
  head(nti)
  str(nti)
  
  # Read Roup Crick - bray matrix
  colnames(rc) <- sub("cDNA_", "", colnames(rc))
  row.names(rc) <- sub("cDNA_", "", row.names(rc))
  rc <- as.matrix(rc)
  rc <- data.frame(as.table(rc))[lower.tri(rc, diag = FALSE), ]
  cat("should got:", (60*60-60)/2, "pair-wise distance\n"); 
  cat("Actually we got:", length(rc$Freq), "pair-wise distance\n")
  cat("the mean RC-bray is:", round(mean(na.omit(rc$Freq)),2), "\n")
  
  row.names(rc) <- paste(rc$Var1, rc$Var2, sep = "_")
  group <- data.frame(row.names=rownames(rc), t(as.data.frame(strsplit(as.character(row.names(rc)), "_"))))
  rc <- data.frame(row.names = rownames(rc), X2 = group$X2, X5 = group$X5, Freq = rc$Freq)
  rc <- rc[which(rc$X2==rc$X5),]
  head(rc)
  str(rc)
  
  # Combine the beta-NTI with RC-bray
  nti.rc <- merge(nti, rc, by=0, all=TRUE)  # merge by="row.names"
  nti.rc <- data.frame(Month = nti.rc$X2.x, nti = nti.rc$Freq.x, rc = nti.rc$Freq.y, row.names = nti.rc$Row.names)
  
  # Invalid the value of RC-bray in which the beta-NTI larger than +2 or less than -2
  for (i in 1:nrow(nti.rc)) {
    if (nti.rc[i,2] > 2 | nti.rc[i,2] < -2) {
      nti.rc[i,3] <- NA
    }
  }
  
  nti.rc$Month <- factor(nti.rc$Month, levels=c("5", "7", "9", "11"))
  head(nti.rc)
  str(nti.rc)
  
  # calculate the relative influence of each assembly processes for each successional stage -----
  # make a matrix to store the number of pairwise samples of each assembly process
  df <- matrix(NA, nrow = 4, ncol = 6)
  df[, 1] <- c("5", "7", "9", "11")
  colnames(df) <- c("Month", "Variable.selection", "Homogeneous.selection", 
                    "Dispersal.limitation", "Homogenizing.dispersal", "Undominated.processes")
  
  for (Month in levels(nti.rc$Month) ) {
    
    cat("\nfor", Month, "Months :\n")
    # Variable selection
    Variable.selection <- nti.rc[nti.rc$Month == Month, ]$nti > 2
    cat("Number of variable  selection :",  table(Variable.selection)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Month == Month, ]), "pairwise samples\n")
    df[df[,1] == Month, 2] <- length(Variable.selection[Variable.selection == TRUE])
    
    # Homogeneous selction
    Homogeneous.selection <- nti.rc[nti.rc$Month == Month, ]$nti < -2
    cat("Number of Homogeneous selection is:", table(Homogeneous.selection)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Month == Month, ]), "pairwise samples\n")
    df[df[,1] == Month, 3] <-  length(Homogeneous.selection[Homogeneous.selection == TRUE]) # table(Homogeneous.selection)["TRUE"] #
    
    # Dispersal limilation
    Dispersal.limilation <- na.omit(nti.rc[nti.rc$Month == Month, ]$rc) > 0.95
    cat("Number of dispersal limitation is:", table(Dispersal.limilation)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Month == Month, ]), "pairwise samples\n")
    df[df[,1] == Month, 4] <- length(Dispersal.limilation[Dispersal.limilation == TRUE])
    
    # Homogenizing dispersal
    Homogenizing.dispersal <- na.omit(nti.rc[nti.rc$Month == Month, ]$rc) < -0.95
    cat("Number of homogenizing dispersal is:", table(Homogenizing.dispersal)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Month == Month, ]), "pairwise samples\n")
    df[df[,1] == Month, 5] <- length(Homogenizing.dispersal[Homogenizing.dispersal == TRUE])
    
    # Undominated processes
    Undominated.processes <- na.omit(nti.rc[nti.rc$Month == Month, ]$rc) <= 0.95 & 
      na.omit(nti.rc[nti.rc$Month == Month, ]$rc) >= -0.95
    cat("Number of Undominated processes is:", table(Undominated.processes)["TRUE"], 
        "within", nrow(nti.rc[nti.rc$Month == Month, ]), "pairwise samples\n")
    df[df[,1] == Month, 6] <- length(Undominated.processes[Undominated.processes == TRUE])
  }
  datalist[[xx]] <- df
}

str(datalist)
df <- do.call(rbind.data.frame, datalist)
df$fraction <- gsub(".{2}$", "", row.names(df))

df1 <- melt(df, id=c("fraction", "Month"))
df1[is.na(df1)] <- 0
df1$value <- as.numeric(df1$value)
cat("should get", 105*4*3, "pairwise comparision index,\nactually got", sum(df1$value), "pairwise comparision index")

df1$value <- round(df1$value*100/105, 2)
df1[,4][df1[,4] == 0] <- NA; df1 <- na.omit(df1)

df1$fraction <- factor(df1$fraction, levels = c("wholeDS", "truncated_ds_dominant", "truncated_ds_rare_without_dominant"), 
                       labels = c("Whole community", "Common biosphere", "Rare biosphere"))

df1$Processes <- factor(df1$variable, levels = c("Variable.selection", "Homogeneous.selection", "Dispersal.limitation", 
                                                 "Homogenizing.dispersal", "Undominated.processes"),
                        labels = c("Variable selection", "Homogeneous selection", "Dispersal limilation", 
                                   "Homogenizing dispersal", "Undominated processes"))

df1$Month <- factor(df1$Month, levels=c("5", "7", "9", "11"), 
                    labels=c("May", "Jul", "Sep", "Nov"))
str(df1)

# stacked-bar plot
(f2 <- ggplot(df1, aes(x=Month, y=value, fill=Processes)) + 
    facet_grid(.~fraction) +
    geom_bar(stat="identity", width=0.64, colour = "black") +
    scale_y_continuous(expand = c(0, 0), limits = c(0,105))+
    scale_fill_manual(values = c("#00A087B2","#FFDB6D", "#DC0000B2", "#4DBBD5B2", "#7570B3")) +
    labs(x="Sampling Month", y="Relative Influence (%)", title="") +
    mytheme)

# combine plots pie & stacked bar plot
(p <- ggarrange(pie, f1, f2, labels = c("A", "B", "C"), legend = "right", common.legend = TRUE, ncol = 1, nrow = 3))

ggsave(paste("Fraction_assembly_processes_", cutoff, ".pdf", sep = ""), width = 12, height = 12, units = "cm", p, scale = 2)

