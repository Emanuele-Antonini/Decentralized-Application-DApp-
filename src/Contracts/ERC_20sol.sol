// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Specificare una versione Solidity più recente e sicura

// Importa i contratti ERC-20 e Ownable di OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Il nostro contratto MySimpleToken eredita le funzionalità da ERC20 e Ownable
contract MySimpleToken is ERC20, Ownable {
    // Il costruttore viene eseguito una sola volta quando il contratto viene deployato.
    // Inizializza il token ERC-20 con un nome e un simbolo.
    // Chi deploya il contratto diventa automaticamente il "owner" grazie a Ownable.
    constructor()
        ERC20("MySimpleToken", "MST") // Chiama il costruttore di ERC20: Nome="MySimpleToken", Simbolo="MST"
        Ownable(msg.sender) // Chiama il costruttore di Ownable: Il deployer è il proprietario
    {
        // Conia una quantità iniziale di token e la assegna al deployer (msg.sender).
        // I token ERC-20 hanno 18 decimali per default, quindi 1000 * (10 ** 18) = 1000 token interi.
        // Utilizziamo un numero arbitrario di token iniziali, ad esempio 1.000.000 token interi.
        _mint(msg.sender, 1_000_000 * 10**decimals()); // Conia 1.000.000 MST al deployer
    }

    // --- Funzioni Aggiuntive (Esempi) ---

    // Funzione per il conio (minting) di nuovi token.
    // Solo il proprietario del contratto può chiamare questa funzione (`onlyOwner`).
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount); // Chiama la funzione interna di minting di ERC20
    }

    // Funzione per la bruciatura (burning) di token dal proprio saldo.
    // Chiunque può bruciare i propri token.
    function burn(uint256 amount) public {
        _burn(msg.sender, amount); // Chiama la funzione interna di burning di ERC20
    }
}