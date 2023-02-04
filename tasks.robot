*** Settings ***
Documentation       Template robot main suite.

Library             RPA.Browser.Selenium    auto_close=${TRUE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs
Library             XML


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orderNo}=    Set Variable    11
    #${orderNo}=    Get and log the value of the vault
    #${orderNo}=    Ask order index
    Open the robot order website
    ${orders}=    Get orders
    Log    ${orders}
    FOR    ${row}    IN    @{orders}
        IF    ${orderNo} == ${row}[Order number]
            #    Close the annoying modal
            Click Button    css:button.btn.btn-dark
            Fill the form    ${row}
            Preview the robot
            Wait Until Keyword Succeeds    10x    0.5s    Submit the order
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
            ${png}=    Take a screenshot of the robot    ${row}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${png}    ${pdf}
            Wait Until Keyword Succeeds    10x    0.5s    Go to order another robot
            BREAK
        ELSE
            CONTINUE
        END
    END
    Create a ZIP file of the receipts
    [Teardown]    Cleanup orders folder


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${ords}=    Read table from CSV    orders.csv    header=True
    RETURN    ${ords}

Fill the form
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://input[@class="form-control" and @type="number"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Log To Console    ${row}

Preview the robot
    Click Button    id:preview

Submit the order
    Click Button    order
    Assert receipt page
    Log To Console    try 1 time

Assert receipt page
    Wait Until Page Contains Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${p}=    Set Variable    ${/}orders${/}orderNo_${order_number}.pdf
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${p}
    RETURN    ${p}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${s}=    Set Variable    ${/}orders${/}pics${/}orderNo_${order_number}.png
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${s}
    RETURN    ${s}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${png}    ${pdf}
    Log    ${png}
    Log    ${pdf}
    #Open Pdf    source_path
    Add Watermark Image To Pdf
    ...    image_path=${OUTPUT_DIR}${png}
    ...    source_path=${OUTPUT_DIR}${pdf}
    ...    output_path=${OUTPUT_DIR}${pdf}

Go to order another robot
    Click Button    order-another
    Assert order page

Assert order page
    Wait Until Page Contains Element    css:button.btn.btn-dark

Create a ZIP file of the receipts
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}orders
    ...    ${OUTPUT_DIR}${/}receipts.zip

Cleanup orders folder
    Remove Directory    ${OUTPUT_DIR}${/}orders    True

Get and log the value of the vault
    ${order}=    Get Secret    order
    RETURN    ${order}[number]

Ask order index
    Add text input    orderNumber    label=Order number
    ${d}=    Run dialog
    RETURN    ${d.orderNumber}
