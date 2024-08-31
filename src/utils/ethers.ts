// lib/contract.ts
import { ethers }  from 'ethers';
const contractAddress: string = '0xYourContractAddress';
const contractABI : any = [];

export async function getContract(): Promise<ethers.Contract> {
    const { providers } : any = ethers;
    const { ethereum } = window as any;
        if (!ethereum) {
            throw new Error('Ethereum object does not exist. Please install MetaMask.');
        }

    const provider = new providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, contractABI, signer);
    return contract;
}