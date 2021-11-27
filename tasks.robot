*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.


*** Settings ***
Library     RPA.HTTP    
Library     RPA.Tables
Library     RPA.Robocorp.Vault
Library     RPA.PDF
Library     RPA.Browser.Selenium
Library     RPA.Dialogs
Library     OperatingSystem
Library     RPA.Archive

*** Keywords ***
Download csv file
    #"csvpath":"https://robotsparebinindustries.com/orders.csv"
    Add text input    name=csvpath  label=URL of the orders CSV file
    ${dialog}=  Show dialog     title=User Input
    ${result}=  Wait dialog    ${dialog}  
    Download    ${result}[csvpath]      overwrite=True  

*** Keywords ***
Open the robot order website
    ${bot_url}=  Get Secret    credential
    Open Available Browser     ${bot_url}[url]    maximized=True

*** Keywords ***
Get Orders   
    ${csv_data}=     Read table from CSV       orders.csv  headers=True
    [Return]    ${csv_data}

*** Keywords ***
Close the annoying modal
    Click Button    css:.btn.btn-dark

*** Keywords ***
Click order
    Click Button   id:order

*** Keywords ***
Order click alert
    ${res}=  Is Element Visible      id:order
    IF  ${res} == True
        Click order
    END

*** Keywords ***
Fill the form
    [Arguments]     ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Element  xpath://*[@id="id-body-${row}[Body]"]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button   id:preview
    Click order
    sleep   5s


*** Keywords ***
Store the receipt as a PDF file
    [Arguments]     ${name}
    Order click alert
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}receipts${/}receipt${name}.pdf
    sleep       3s      
    Screenshot    id:robot-preview-image   filename=${CURDIR}${/}output${/}Robot_Img${name}.PNG
    ${receipt_pdf}=    Open Pdf      ${CURDIR}${/}receipts${/}receipt${name}.pdf
    ${robot_img}=   Create List      ${CURDIR}${/}receipts${/}receipt${name}.pdf  
    ...            ${CURDIR}${/}output${/}Robot_Img${name}.PNG
    Add Files To Pdf    ${robot_img}     ${CURDIR}${/}receipts${/}receipt${name}.pdf
    Close Pdf   ${receipt_pdf}
    Click Element When Visible      id:order-another
    Remove File     ${CURDIR}${/}output${/}Robot_Img${name}.PNG  

*** Keywords ***
Zip archives
    Archive Folder With Zip     ${CURDIR}${/}receipts     ${CURDIR}${/}output${/}PDF receipts.zip

*** Tasks ***
Order Robots from RobotSpareBin
    Download csv file
    Open the robot order website
    ${orders}=  Get Orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form   ${row}
        Order click alert
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
    END
    Close Browser
    Zip archives
