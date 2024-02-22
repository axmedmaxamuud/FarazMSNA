## Data preparation script
rm(list = ls())
today <- Sys.Date()

# load packages
if (!require("pacman")) install.packages("pacman")
p_load(
  rio,
  tidyverse,
  crayon,
  hypegrammaR,
  sjmisc,
  koboquest,
  reshape2,
  openxlsx,
  readxl
)

# load clean data
data <- read_excel("input/data/clean_data.xlsx", guess_max = 50000)

questions <- import("input/tool/kobo_tool.xlsx", sheet = "survey") %>% 
  # select(-1) %>% 
  filter(!is.na(name))

# Making sure binaries of SM questions are stored as numerical values (0/1) instead of ("0"/"1")
binary_q <- questions %>% filter(grepl("^select_multiple",type)) %>% pull(name)

binary_q_regex <- paste0("(",paste(paste0("^",questions %>% filter(grepl("select_multiple",type)) %>% pull(name),"\\."),collapse = '|'),")")
data <- mutate_at(data,
                  names(data)[str_detect(pattern = binary_q_regex,string = names(data))]
                  ,as.numeric)

# Remove binary fields added to select one questions if any
regex_expr <- paste0("(",paste(paste0("^",questions %>% filter(grepl("select_one",type)) %>% pull(name),"\\."),collapse = '|'),")")

names(data)[str_detect(pattern = regex_expr,string = names(data))]

data <- data %>% select(-any_of(c(names(data)[str_detect(pattern = regex_expr,string = names(data))])))

# Making sure numerical variables are formatted correctly
num_q <- questions %>% filter(type %in% c("calculate","integer")) %>% pull(name)

num_q <- num_q[num_q %in% names(data)]

data <- mutate_at(data,num_q,as.numeric)

# Remove non needed questions from data prior analysis
questions_to_remove <- c("start",
                         "end",
                         "date_assessment",
                         "deviceid",
                         "survey_modality",
                         "enum",
                         "respondentcode",
                         "_id",
                         "_uuid",
                         "_submission_time",
                         "_validation_status",
                         "_notes",
                         "_status",
                         "_submitted_by",
                         "__version__",
                         "_tags",
                         "_index"
)


data <- data %>% select(-any_of(questions_to_remove))

# Export final clean data
write.xlsx(data, paste0("input/data/results_table_data_",today,".xlsx"))
