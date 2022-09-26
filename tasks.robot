*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.PDF
Library    RPA.Dialogs
Library    RPA.Tables
Library    RPA.HTTP
Library    OperatingSystem
Library    RPA.Archive
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs

*** Variables ***
${file}    https://robotsparebinindustries.com/orders.csv
${DOWNLOAD_PATH}=   ${OUTPUT DIR}${/}orders.csv
${RECEIPT_PATH}=    ${OUTPUT DIR}${/}RECEIPTS
${ZIPFILE}=    ${OUTPUT DIR}${/}ORDERS
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${file}=    Initiate Process
    ${orders}=    Get Orders    ${file}
    Open the robot order website
    Get Vault Super Secret
    FOR    ${row}    IN    @{orders}
        Fill in Order    ${row}
        Wait Until Keyword Succeeds    10x    0.5 sec    Submit Order
        Create Receipt    ${row}
        Select Next Order
    END
    Zip ORDERS FOLDER & Clean Up



*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Accept Cookies

Accept Cookies
    Click Button    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]

Get Orders
    [Arguments]    ${file}
    Download    ${file}    target_file=${DOWNLOAD_PATH}    overwrite=${True}
    ${order_table}=    Read table from CSV    ${DOWNLOAD_PATH}
    RETURN    ${order_table}

Fill in Order
    [Arguments]    ${row}
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input    ${row}[Address]
    Select Radio Button    body   ${row}[Body]
    Select From List By Value    id:head    ${row}[Head]
    Click Button    id:preview
    

Submit Order
    Click Button    order
    Wait Until Element Contains    receipt     Receipt
    
Create Receipt
    [Arguments]    ${row}
    #receipt    ${RECEIPT_PATH}${/}${row}[Order number].pdf
    ${html_receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${html_receipt}    ${RECEIPT_PATH}${/}${row}[Order number].pdf
    Screenshot    id:robot-preview-image    filename=${RECEIPT_PATH}${/}${row}[Order number].PNG
    Open Pdf    ${RECEIPT_PATH}${/}${row}[Order number].pdf
    ${receipt}=    Create List    ${RECEIPT_PATH}${/}${row}[Order number].pdf
    ...    ${RECEIPT_PATH}${/}${row}[Order number].PNG
    
    Add Files To Pdf    ${receipt}    ${RECEIPT_PATH}${/}${row}[Order number].pdf    append=False
    Close Pdf    ${RECEIPT_PATH}${/}${row}[Order number].pdf
    Move File    ${RECEIPT_PATH}${/}${row}[Order number].pdf    ${OUTPUT DIR}${/}ORDERS${/}${row}[Order number].pdf

Select Next Order
    Click Button    id:order-another
    Accept Cookies

Zip ORDERS FOLDER & Clean Up
    Archive Folder With Zip    ${ZIPFILE}    ${OUTPUT_DIR}${/}Orders.zip
    Close All Browsers
    Remove Directory    ${OUTPUT DIR}${/}ORDERS${/}    recursive=${True}
    Remove Directory    ${RECEIPT_PATH}    recursive=${True}
    Remove File    ${OUTPUT_DIR}${/}Orders.zip
    Remove File    ${OUTPUT_DIR}${/}orders.csv

Initiate Process
    Add heading    Welcome Back!
    Add text input    link    label=File link
    Run dialog
    RETURN    label


Get Vault Super Secret
    ${secret}=    Get Secret    supersecret
    Log    ${secret}[ABBA]

