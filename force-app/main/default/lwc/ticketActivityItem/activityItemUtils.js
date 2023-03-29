import { TicketStatusType, TicketStageType } from "c/csUtils";

export const TICKET_ACTIVITY_TYPE = {
    ADD_PARTICIPANT: "add participant",
    ATTACHMENT_UPLOAD: "attachment upload",
    CREATE_TICKET: "create ticket",
    COLLECT_SIGNATURES: "collect signatures",
    COLLECT_SIGNATURES_CANCELLED: "collect signatures cancelled",
    COORDINATOR_REASSIGNMENT: "coordinator reassignment",
    DOCUMENT_UPLOAD: "document upload",
    DOWNLOAD_DOCUMENT: "download document",
    E_SIGNATURE: "esignature",
    INTAKE_FORM_EDIT: "intake form edit",
    JUDGMENT_RESULT_STATUS_UPDATE: "judgment result status update",
    JUDGMENT_RESULT_REASSIGNMENT: "judgment result reassignment",
    NEXT_STAGE: "next stage",
    PREVIOUS_STAGE: "previous stage",
    REMOVE_PARTICIPANT: "remove participant",
    RENAME_TICKET: "rename ticket",
    RESET_APPROVALS: "reset approvals",
    SHARE_DOCUMENT: "share document",
    SIGNATURE_UPLOAD: "signature upload",
    STATUS_UPDATE: "status update",
    TICKET_COMPLETION: "ticket completion"
};

const joinWith = (list, { delimiter, lastDelimiter }) => {
    const length = list.length;
    return `${list.slice(0, length - 1).join(delimiter)}` + `${lastDelimiter}${list[length - 1]}`;
};
const joinStrings = (array) => joinWith(array, { delimiter: ", ", lastDelimiter: " and " });
const parseUser = (user) => (user?.name ? user.name : "Undefined User");

export const getUnassignedUserDisplay = (stage) => {
    switch (stage) {
        case TicketStageType.Review:
            return "Unassigned Reviewer";
        case TicketStageType.Sign:
            return "Unassigned Signer";
        case TicketStageType.Finalize:
            return "Unassigned Finalizer";
        default:
            return "Unassigned User";
    }
};

export function getActivityString({ action, data, user, users }) {
    const { name: userName } = user;
    switch (action.toLowerCase()) {
        case TICKET_ACTIVITY_TYPE.ADD_PARTICIPANT: {
            const { user } = data;
            return `{{${userName}}} added {{${parseUser(user)}}} as a participant.`;
        }
        case TICKET_ACTIVITY_TYPE.ATTACHMENT_UPLOAD: {
            const { user } = data;
            return `{{${parseUser(user)}}} uploaded a new attachment.`;
        }
        case TICKET_ACTIVITY_TYPE.COLLECT_SIGNATURES: {
            const { externalUsers, internalUsers } = data;
            const getMentionString = ({ email, name }) => `{{${name} (${email})}}`;
            const fieldsString = joinStrings(internalUsers.concat(externalUsers).map(getMentionString));
            return `{{${userName}}} sent the document for signature to ${fieldsString}.`;
        }
        case TICKET_ACTIVITY_TYPE.COLLECT_SIGNATURES_CANCELLED: {
            const { signingService } = data;
            return `${
                signingService.toLowerCase() === "adobesign" ? "AdobeSign" : "DocuSign"
            } failed to process the file for signatures. Please create a new version of your file and try sending it for signatures again.`;
        }
        case TICKET_ACTIVITY_TYPE.COORDINATOR_REASSIGNMENT: {
            const { newUser, oldUser, stage } = data;
            return `{{${userName}}} reassigned the {{${stage}}} coordinator from {{${parseUser(
                oldUser
            )}}} to {{${parseUser(newUser)}}}.`;
        }
        case TICKET_ACTIVITY_TYPE.CREATE_TICKET: {
            return `{{${userName}}} started {{${data.document.name}}}.`;
        }
        case TICKET_ACTIVITY_TYPE.DOCUMENT_UPLOAD: {
            const { fileName, version } = data;

            return `{{${userName}}} uploaded {{${fileName}}} which generated version {{${version.tag}}}.`;
        }
        case TICKET_ACTIVITY_TYPE.DOWNLOAD_DOCUMENT: {
            const { version } = data;

            return `{{${userName}}} downloaded document version {{${version.tag}}}.`;
        }
        case TICKET_ACTIVITY_TYPE.E_SIGNATURE: {
            const { externalUser, internalUser } = data;
            const userMention = internalUser ? `{{${parseUser(internalUser)}}}` : `{{${parseUser(externalUser)}}}`;
            return `${userMention} signed the document via eSignature.`;
        }
        case TICKET_ACTIVITY_TYPE.INTAKE_FORM_EDIT: {
            const { created, version } = data;

            return created
                ? `{{${userName}}} changed form information fields which generated document version {{${version.tag}}}.`
                : `{{${userName}}} changed form information fields.`;
        }
        case TICKET_ACTIVITY_TYPE.JUDGMENT_RESULT_STATUS_UPDATE: {
            const { status } = data;
            let actionString = "";
            if (status === TicketStatusType.Approved) {
                actionString = "completed";
            } else if (status === TicketStatusType.Rejected) {
                actionString = "rejected";
            } else if (status === TicketStatusType.Done) {
                actionString = "marked as done";
            } else if (status === TicketStatusType.Pending) {
                actionString = "reset";
            }
            return `{{${userName}}} ${actionString} the following item.`;
        }
        case TICKET_ACTIVITY_TYPE.NEXT_STAGE:
        case TICKET_ACTIVITY_TYPE.PREVIOUS_STAGE:
        case TICKET_ACTIVITY_TYPE.TICKET_COMPLETION: {
            const { newStage, oldStage } = data;
            return userName
                ? `{{${userName}}} moved the document from {{${oldStage}}} to {{${newStage}}}.`
                : `The document was moved from {{${oldStage}}} to {{${newStage}}}.`;
        }
        case TICKET_ACTIVITY_TYPE.JUDGMENT_RESULT_REASSIGNMENT: {
            const { name: taskName, newUser, oldUser, phase, currentStage } = data;
            const getUserString = ({ email, isInternal, name }) =>
                !name
                    ? `{{${getUnassignedUserDisplay(currentStage)}}}`
                    : isInternal
                    ? `{{${name} (${email})}}`
                    : `{{External User}}`;
            return `{{${userName}}} reassigned {{${taskName}}} in {{${phase.name}}} from ${getUserString(
                oldUser
            )} to ${getUserString(newUser)}.`;
        }
        case TICKET_ACTIVITY_TYPE.REMOVE_PARTICIPANT: {
            const { user } = data;
            return `{{${userName}}} removed {{${parseUser(user)}}} as a participant.`;
        }
        case TICKET_ACTIVITY_TYPE.RENAME_TICKET: {
            const { newName, oldName } = data;
            return `{{${userName}}} renamed the ticket from {{${oldName}}} to {{${newName}}}.`;
        }
        case TICKET_ACTIVITY_TYPE.RESET_APPROVALS: {
            return `{{${userName}}} reset all items.`;
        }
        case TICKET_ACTIVITY_TYPE.SHARE_DOCUMENT: {
            const { emails, version } = data;
            const fieldsString = joinStrings(emails.map((email) => `{{${email}}}`));
            return `{{${userName}}} shared document version {{${version.tag}}} with ${fieldsString}.`;
        }
        case TICKET_ACTIVITY_TYPE.SIGNATURE_UPLOAD: {
            const { externalUsers, internalUsers } = data;
            const internaluserNames = internalUsers.map(({ name }) => name);
            const getMentionString = ({ name, email }) => `{{${name} (${email})}}`;
            const fieldsString = joinStrings(internalUsers.concat(externalUsers).map(getMentionString));
            return `{{${userName}}} uploaded a document with signature(s) from ${fieldsString}.`;
        }
        default: {
            return null;
        }
    }
}