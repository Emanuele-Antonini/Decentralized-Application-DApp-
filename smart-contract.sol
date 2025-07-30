// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 1. Importa i contratti di OpenZeppelin per funzionalità comuni e sicure
import "@openzeppelin/contracts/access/Ownable.sol"; // Per gestire un proprietario del contratto
import "@openzeppelin/contracts/utils/Counters.sol"; // Per generare ID unici in modo sicuro

// --- 2. Definizione del Contratto Principale: ProjectManager ---
// Eredita da Ownable per avere un proprietario che può gestire alcune funzioni
contract ProjectManager is Ownable {
    // Usa Counters per generare ID univoci per progetti e proposte
    using Counters for Counters.Counter;

    // --- 3. Strutture Dati Complesse ---
    struct Project {
        Counters.Counter projectId; // ID unico del progetto
        string name;                // Nome del progetto
        address creator;            // Chi ha creato il progetto
        uint creationTime;          // Timestamp di creazione
        Status status;              // Stato del progetto (es. Inizializzato, Attivo, Completato, Cancellato)
        uint totalProposals;        // Numero totale di proposte per questo progetto
        mapping(uint => Proposal) proposals; // Mappa ID proposta a Proposta
    }

    struct Proposal {
        Counters.Counter proposalId;   // ID unico della proposta
        Counters.Counter projectId;    // ID del progetto a cui si riferisce
        string description;            // Descrizione della proposta
        address proposer;              // Chi ha proposto
        uint creationTime;             // Timestamp di creazione
        uint voteEndTime;              // Quando finisce la votazione
        uint yesVotes;                 // Voti "Sì"
        uint noVotes;                  // Voti "No"
        Status status;                 // Stato della proposta (es. Iniziale, Attiva, Approvata, Rifiutata)
        mapping(address => bool) hasVoted; // Mappa indirizzo a booleano: true se l'utente ha votato
    }

    enum Status { Initial, Active, Completed, Cancelled, Approved, Rejected }

    // --- 4. Mappature dello Stato Globale ---
    Counters.Counter private _nextProjectId; // Contatore per i nuovi ID progetto
    mapping(uint => Project) public projects; // Mappa ID progetto a Progetto

    Counters.Counter private _nextProposalId; // Contatore per i nuovi ID proposta
    // Non abbiamo una mappa globale per le proposte qui perché sono annidate nei progetti.

    // --- 5. Eventi per Trasparenza e Interfacce Utente ---
    event ProjectCreated(uint indexed projectId, string name, address creator, uint creationTime);
    event ProjectStatusChanged(uint indexed projectId, Status newStatus);
    event ProposalCreated(uint indexed projectId, uint indexed proposalId, string description, address proposer);
    event VoteCast(uint indexed proposalId, address voter, bool vote);
    event ProposalStatusChanged(uint indexed proposalId, Status newStatus);

    // --- 6. Funzioni di Creazione e Modifica ---

    /**
     * @dev Crea un nuovo progetto.
     * @param _name Il nome del progetto.
     */
    function createProject(string memory _name) public {
        _nextProjectId.increment();
        uint newProjectId = _nextProjectId.current();

        Project storage newProject = projects[newProjectId];
        newProject.projectId = newProjectId; // Assegna il Contatore all'ID
        newProject.name = _name;
        newProject.creator = msg.sender;
        newProject.creationTime = block.timestamp;
        newProject.status = Status.Initial;
        // nextProjectId per proposals nel progetto inizializzato a 0 dal costruttore implicito

        emit ProjectCreated(newProjectId, _name, msg.sender, block.timestamp);
    }

    /**
     * @dev Permette al proprietario del contratto di cambiare lo stato di un progetto.
     * @param _projectId L'ID del progetto.
     * @param _newStatus Il nuovo stato del progetto.
     */
    function setProjectStatus(uint _projectId, Status _newStatus) public onlyOwner {
        require(projects[_projectId].creator != address(0), "Project does not exist."); // Controlla esistenza
        projects[_projectId].status = _newStatus;
        emit ProjectStatusChanged(_projectId, _newStatus);
    }

    /**
     * @dev Crea una nuova proposta per un progetto esistente.
     * @param _projectId L'ID del progetto a cui si riferisce la proposta.
     * @param _description La descrizione della proposta.
     * @param _votingDuration Durata della votazione in secondi.
     */
    function createProposal(uint _projectId, string memory _description, uint _votingDuration) public {
        require(projects[_projectId].creator != address(0), "Project does not exist.");
        require(_votingDuration > 0, "Voting duration must be greater than 0.");

        // Incrementa il contatore delle proposte per questo specifico progetto
        projects[_projectId].totalProposals++;
        uint newProposalId = projects[_projectId].totalProposals; // ID relativo al progetto

        Proposal storage newProposal = projects[_projectId].proposals[newProposalId];
        newProposal.proposalId = newProposalId;
        newProposal.projectId = _projectId;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.creationTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp + _votingDuration;
        newProposal.yesVotes = 0;
        newProposal.noVotes = 0;
        newProposal.status = Status.Initial; // Inizialmente in stato 'Initial'

        emit ProposalCreated(_projectId, newProposalId, _description, msg.sender);
    }

    /**
     * @dev Permette a un utente di votare su una proposta.
     * @param _projectId L'ID del progetto.
     * @param _proposalId L'ID della proposta all'interno del progetto.
     * @param _vote True per "Sì", False per "No".
     */
    function voteOnProposal(uint _projectId, uint _proposalId, bool _vote) public {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist.");
        Proposal storage proposal = project.proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist."); // Controlla esistenza proposta

        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal.");

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Funzione per finalizzare una proposta dopo che il periodo di votazione è terminato.
     * Può essere chiamata da chiunque per aggiornare lo stato.
     * @param _projectId L'ID del progetto.
     * @param _proposalId L'ID della proposta.
     */
    function finalizeProposal(uint _projectId, uint _proposalId) public {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist.");
        Proposal storage proposal = project.proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist.");

        require(block.timestamp > proposal.voteEndTime, "Voting period is still active.");
        require(proposal.status == Status.Initial || proposal.status == Status.Active, "Proposal already finalized.");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = Status.Approved;
        } else {
            proposal.status = Status.Rejected;
        }
        emit ProposalStatusChanged(_proposalId, proposal.status);
    }

    // --- 7. Funzioni di Lettura (View) ---

    /**
     * @dev Restituisce i dettagli di un progetto specifico.
     * @param _projectId L'ID del progetto.
     * @return Dettagli del progetto.
     */
    function getProject(uint _projectId) public view returns (
        uint id, string memory name, address creator, uint creationTime, Status status, uint totalProposalsCount
    ) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist.");
        return (
            project.projectId.current(), // Usiamo .current() per i Counters
            project.name,
            project.creator,
            project.creationTime,
            project.status,
            project.totalProposals
        );
    }

    /**
     * @dev Restituisce i dettagli di una proposta specifica all'interno di un progetto.
     * @param _projectId L'ID del progetto.
     * @param _proposalId L'ID della proposta.
     * @return Dettagli della proposta.
     */
    function getProposal(uint _projectId, uint _proposalId) public view returns (
        uint id, uint projectId, string memory description, address proposer, uint creationTime,
        uint voteEndTime, uint yesVotes, uint noVotes, Status status
    ) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist.");
        Proposal storage proposal = project.proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist.");
        return (
            proposal.proposalId.current(), // Usiamo .current() per i Counters
            proposal.projectId.current(),
            proposal.description,
            proposal.proposer,
            proposal.creationTime,
            proposal.voteEndTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.status
        );
    }

    /**
     * @dev Restituisce lo stato di votazione di un utente per una proposta.
     * @param _projectId L'ID del progetto.
     * @param _proposalId L'ID della proposta.
     * @param _voter L'indirizzo dell'utente.
     * @return True se l'utente ha votato, false altrimenti.
     */
    function hasUserVoted(uint _projectId, uint _proposalId, address _voter) public view returns (bool) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist.");
        Proposal storage proposal = project.proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist.");
        return proposal.hasVoted[_voter];
    }
}