*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    0.5s
${DEFAULT_ORDERS_DOWNLOAD_PATH}=    https://robotsparebinindustries.com/orders.csv

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders download path
    Add text    Optional orders.csv file location that can be downloaded. If nothing provided, default will be used.
    Add text input    path    label=orders.csv path    placeholder=${DEFAULT_ORDERS_DOWNLOAD_PATH}
    ${response}=    Run dialog    title=Order file location
    ${orders_path_len}=    Get Length    ${response.path}
    ${orders_path}=    Set Variable If      ${orders_path_len} > 0    ${response.path}    ${DEFAULT_ORDERS_DOWNLOAD_PATH}
    [Return]    ${orders_path}

Get orders
    ${orders_download_path}=    Get orders download path
    ${orders_output}=    Set Variable    ${OUTPUT_DIR}${/}orders.csv
    Download    ${orders_download_path}    target_file=${orders_output}    overwrite=True
    ${orders}=    Read table from CSV    ${orders_output}    dialect=excel
    [Return]    ${orders}

Close the annoying modal
    Click Button When Visible    css:.alert-buttons > button:nth-child(1)

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[type=number]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview

Sumit order and wait for next step
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt    timeout=1

Submit the order
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Sumit order and wait for next step

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${OUTPUT_DIR}${/}${order_number}.pdf
    [Return]    ${OUTPUT_DIR}${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To PDF
    ...             image_path=${screenshot}
    ...             source_path=${pdf}
    ...             output_path=${pdf}

Go to order another robot
    Click Button When Visible    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip  ${OUTPUT_DIR}${/}    r{OUTPUT_DIR}${/}receipts.zip  include=*.pdf

Share sacred knowladge
    ${secrets}=    Get Secret    secrets
    Log    ${secrets}[meaning_of_life]

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Share sacred knowladge
    [Teardown]    Close browser
