-- Preparing basic data for each user
WITH cohort_data AS (
          SELECT
             user_pseudo_id,
            -- Round the subscription start date to the beginning of the week
            -- For example, if the subscription started on 2021-01-03, it is rounded up to 2021-01-01
            DATE_TRUNC(subscription_start, WEEK) AS cohort_start_week,
            -- Determine the last date of the activity:
            -- If the user unsubscribed - take the unsubscribe date
            -- If the user is active (subscription_end is null) - take the analysis date (2021-02-07)
            -- Also round up to the beginning of the week
            DATE_TRUNC(COALESCE(subscription_end, DATE '2021-02-07'), WEEK) AS check_week,
         -- Create an array of all weeks of user activity
         -- For example, if the subscription lasted 3 weeks, we will get an array of 3 dates:
         -- [2021-01-01, 2021-01-08, 2021-01-15]
            GENERATE_DATE_ARRAY(
               DATE_TRUNC(subscription_start, WEEK), -- start date
               DATE_TRUNC(COALESCE(subscription_end, DATE '2021-02-07'), WEEK), -- end date
              INTERVAL 1 WEEK -- step in one week
              ) AS active_weeks
         FROM
          `subscriptions`
),

-- Calculating retention for each week
weekly_retention AS (
        SELECT
            -- Group by subscription start week (cohort)
           cohort_start_week,
           -- Calculate which week it is for the user
           -- For example: 0 - first week, 1 - second week, etc.
           DATE_DIFF(week, cohort_start_week, WEEK) AS week_number,
          -- Calculate the number of unique users
          COUNT(DISTINCT user_pseudo_id) AS active_users
       FROM
         cohort_data,
         -- Expand the array of weeks into separate rows
         -- For example, from [2021-01-01, 2021-01-08, 2021-01-15]
         -- will be getting three separate rows
         UNNEST(active_weeks) AS week
       WHERE
        -- Limit the analysis to the first 6 weeks
        DATE_DIFF(week, cohort_start_week, WEEK) BETWEEN 0 AND 6
      GROUP BY
        cohort_start_week,
        week_number
)

-- Generate the final table
SELECT
     -- Subscription start week (cohort)
     cohort_start_week,
     -- For each week (from 0 to 6), create a separate column
     -- If this is the desired week (week_number = X), take the number of active users
     -- If not, set to 0
     SUM(CASE WHEN week_number = 0 THEN active_users ELSE 0 END) AS week_0,
     SUM(CASE WHEN week_number = 1 THEN active_users ELSE 0 END) AS week_1,
     SUM(CASE WHEN week_number = 2 THEN active_users ELSE 0 END) AS week_2,
     SUM(CASE WHEN week_number = 3 THEN active_users ELSE 0 END) AS week_3,
     SUM(CASE WHEN week_number = 4 THEN active_users ELSE 0 END) AS week_4,
     SUM(CASE WHEN week_number = 5 THEN active_users ELSE 0 END) AS week_5,
     SUM(CASE WHEN week_number = 6 THEN active_users ELSE 0 END) AS week_6
FROM
    weekly_retention
-- Group by cohorts
GROUP BY
   cohort_start_week

ORDER BY
   cohort_start_week;