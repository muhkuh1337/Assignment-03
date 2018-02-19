# run_analysis.R
library(data.table)
library(dplyr)

# 0. paths
CleanDataPath         <- './clean_data'
RawDataPath           <- './raw_data/UCI_HAR_Dataset'
MetaDataActivityPath  <- paste(RawDataPath, 'activity_labels.txt', sep = '/') 
MetaDataXFeaturesPath <- paste(RawDataPath, 'features.txt', sep = '/')
TestSetXPath          <- paste(RawDataPath, 'test', 'X_test.txt', sep = '/')
TestSetYPath          <- paste(RawDataPath, 'test', 'y_test.txt', sep = '/')
TestSetSubjects       <- paste(RawDataPath, 'test', 'subject_test.txt', sep = '/')
TrainSetXPath         <- paste(RawDataPath, 'train', 'X_train.txt', sep = '/')
TrainSetYPath         <- paste(RawDataPath, 'train', 'y_train.txt', sep = '/')
TrainSetSubjects      <- paste(RawDataPath, 'train', 'subject_train.txt', sep = '/')

# 1. read meta data
ActivityLabels <- data.table::fread(MetaDataActivityPath, col.names = c("Digit", "Label"))
FeaturesX      <- data.table::fread(MetaDataXFeaturesPath, col.names = c("Index", "Name"))

# 2. read data
SetXTest      <- data.table::fread(TestSetXPath)
SetYTest      <- data.table::fread(TestSetYPath)
SetXTrain     <- data.table::fread(TrainSetXPath)
SetYTrain     <- data.table::fread(TrainSetYPath)
SubjectsTrain <- data.table::fread(TrainSetSubjects)
SubjectsTest  <- data.table::fread(TestSetSubjects)

# 3. Merges the training and the test sets to create one data set called Data
CompleteX        <- data.table::rbindlist(list(SetXTrain, SetXTest))
CompleteY        <- data.table::rbindlist(list(SetYTrain, SetYTest))
CompleteSubjects <- data.table::rbindlist(list(SubjectsTrain, SubjectsTest))
Data             <- cbind(CompleteSubjects, CompleteY, CompleteX)

# 4. Appropriately labels the data set with descriptive variable names.
# complies with Lecture 04: all lower case, descriptive, no duplicates, no underscores/dots/whitespaces
FeaturesX[, Name := tolower(gsub('[-,()_]', '', FeaturesX$Name, fixed = FALSE))]
colnames(Data) <- c("subject", "activity", FeaturesX$Name)

# 5. Uses descriptive activity names to name the activities in the data set
Data[ , activity := factor(Data$activity, levels = ActivityLabels$Digit, labels = ActivityLabels$Label)]
Data[ , subject := as.factor(subject)]

# 6. Extracts only the measurements on the mean and standard deviation for each measurement.
OnlyMeanAndStdMeasurements <- Data[, grepl('mean|std|^subject$|^activity$' , colnames(Data), fixed = FALSE), with = FALSE]

# 7. From the data set in step 6, creates a second, independent tidy data set with the average of each variable for each activity and each subject.
GroupedBy <- dplyr::group_by(OnlyMeanAndStdMeasurements, subject, activity)
SummarisedOnlyMeanAndStdMeasurements <- as.data.table(summarise_all(GroupedBy, funs(mean(., na.rm = TRUE))))
colnames(SummarisedOnlyMeanAndStdMeasurements) <- sapply(colnames(SummarisedOnlyMeanAndStdMeasurements), function(x) {
  if (!grepl('^activity$|^subject$', x, fixed = FALSE)) {
    return(paste0('mean', x))
  } else {
    return(x)
  }
})

# 8. store cleaned data to file
if (!dir.exists(CleanDataPath)) {
  dir.create(CleanDataPath)
}
write.csv(Data, file = paste(CleanDataPath, 'data.csv', sep = '/'))
write.csv(OnlyMeanAndStdMeasurements, file = paste(CleanDataPath, 'OnlyMeanAndStdMeasurements.csv', sep = '/'))
write.csv(SummarisedOnlyMeanAndStdMeasurements, file = paste(CleanDataPath, 'summary.csv', sep = '/'))
